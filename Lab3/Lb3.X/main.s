; Archivo:     main.S
; Dispositivo: PIC16F8870
; Autor:       Oscar Fuentes
; Compilador:  pic-as (v2.30), MPLABX V5.45
;
; Programa:    contador con tiempo y contador con botón
; Hardware:    LEDs en el puerto B y display 7 segmentos puerto C
;
; Creado: 16 feb, 2021
; última modificación: 16 feb, 2021

; Assembly source line config statements

PROCESSOR 16F887
#include <xc.inc>

; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = ON            ; Power-up Timer Enable bit (PWRT enabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = ON              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)
  
  PSECT udata_bank0		;common memory
    var1: DS 1			;1 byte
    zero: DS 1			;1 byte
    
  PSECT resVect, class=CODE, abs, delta=2
 ;-----------vector reset-------------------------------------------------------
 ORG 00h		;posición 0000h para el reset
 resetVec:
    PAGESEL main
    goto main
    
 PSECT code, delta=2, abs
 ORG 100h		;posición para el código
 
tabla:
    clrf    PCLATH	    ; El registro de PCLATH se coloca en 0
    bsf	    PCLATH, 0	    ; El valor de PCLAT adquiere el valor 01
    andlw   0x0f	    ; Se restringe el valor máximo de la tabla
    addwf   PCL		    ; PC = PCL + PLACTH + W
    retlw   00111111B	    ; 0
    retlw   00000110B	    ; 1
    retlw   01011011B	    ; 2
    retlw   01001111B	    ; 3
    retlw   01100110B	    ; 4
    retlw   01101101B	    ; 5
    retlw   01111101B	    ; 6
    retlw   00000111B	    ; 7
    retlw   01111111B	    ; 8
    retlw   01100111B	    ; 9
    retlw   01110111B	    ; A
    retlw   01111100B	    ; B
    retlw   00111001B	    ; C
    retlw   01011110B	    ; D
    retlw   01111001B	    ; E
    retlw   01110001B	    ; F
    return
   
 ;---------------------configuración--------------------------------------------
 main:
    banksel ANSEL	    ;
    clrf    ANSEL	    ; Las entradas/salidas del puerto A son digitales
    clrf    ANSELH	    ; Las entradas/salidas del puerto B son digitales
    
    banksel TRISA	    ;
    movlw   11111111B	    ; Todas los pines de A serán entradas
    movwf   TRISA	    ;
    movlw   11110000B	    ; Los primeros 4 pines de B serán de salida
    movwf   TRISB	    ;
    clrf    TRISC	    ; Todos los pines de C serán salida
    clrf    TRISD	    ; Todos los pines de D serán salida
    
    banksel PORTA	    ;
    clrf    PORTB	    ; Los puertos que son de salida se colocan en 0
    clrf    PORTC	    ;
    clrf    PORTD	    ;
    
    call    config_clk	    ; Se llama a la configuración del reloj
    call    config_tmr0	    ; Se configuración el tmr0
 
;----------------------loop principal-------------------------------------------
 loop:
    bsf	    zero,0	    ; El bit menos sign. de zero se coloca en 1
    btfsc   PORTA, 0	    ; Se revisa si el primer pin de A recibe señal
    call    inc_cont2	    ; Se incrementa el contador 2
    btfsc   PORTA, 1	    ; Se revisa si el segundo pin de A recibe señal
    call    dec_cont2	    ; Se decrementa el contador 2
    btfss   T0IF	    ; Se revisa si la bandera del tmr0 está en 1
    goto    $-1		    ; Si no es así, se ejecuta el testeo nuevamente
    call    ttmr0	    ; Si la bandera está encendida se reincia el tmr0
    incf    PORTB	    ; Se incrementa el puerto B
    call    ban		    ; Se llama a la rutina a cargo de la bandera de igual
    goto    loop	    ; Se vuelve a ejecutar el loop
    
;-------------------------sub-rutinas-------------------------------------------

config_clk:
    banksel OSCCON	    ;
    bcf	    IRCF2	    ;
    bsf	    IRCF1	    ;
    bcf	    IRCF0	    ; Se configura el IRCF a 010, que son 250kHz de clk
    bsf	    SCS		    ; Se utiliza el oscilador interno para el clk
    return
    
config_tmr0:
    banksel TRISA	    ;
    bcf	    T0CS	    ; Se utiliza el ciclo de reloj interno
    bcf	    PSA		    ;
    bsf	    PS2		    ;
    bsf	    PS1		    ;
    bsf	    PS0		    ; El valor del prescaler es 111 lo que es 1:256
    call    ttmr0	    ; Se llama al reinicio del tmr0
    return
    
ttmr0:
    btfsc   zero, 0	    ; Si el primer bit es 0 no se coloca en 0 la bandera
    bcf	    PORTD, 0	    ; Se coloca en 0 la bandera que indica igualdad
    banksel PORTA	    ;
    movlw   134		    ; Se carga el valor 134 al registro del tmr0
    movwf   TMR0	    ;
    bcf	    T0IF	    ; Se coloca en 0 la bandera del tmr0
    return

inc_cont2:
    btfsc   PORTA, 0	    ; Si el botón del pin 1 del puerto A se suelta
    goto    $-1		    ;
    incf    var1, 1	    ; Se incrementa la variable y se almacena en sí mismo
    movf    var1, 0	    ; Se mueve el valor de la variable a W
    call    tabla	    ; Se llama la tabla de los valores hexadecimales
    movwf   PORTC	    ; El valor de W (dado por la tabla) se coloca en PORTC
    return
    
dec_cont2:
    btfsc   PORTA, 1	    ; Si el botón del pin 2 del puerto A se suelta
    goto    $-1		    ;
    decf    var1, 1	    ; Se decrementa la variable y se almacena en sí mismo
    movf    var1, 0	    ; Se mueve el valor de la variable a W
    call    tabla	    ; Se llama la tabla con los valores hexadecimales
    movwf   PORTC	    ; El valor de W (dado por la tabla) se coloca en PORTC
    return
    
 ban:
    movf    var1, 0	    ; El valor de la variable 1 se mueve a W
    subwf   PORTB, 0	    ; PORTB - W
    btfsc   STATUS, 2	    ; Si el valor de la bandera Z es 0 omite la inst. sig.
    bsf	    PORTD, 0	    ; Sino se enciende el led del puerto D
    btfsc   STATUS, 2	    ; Si el valor de la bandera Z es 0 omite la inst. sig.
    clrf    PORTB	    ; Sino el valor del PORTB (contador 1) se pone en 0
    btfsc   STATUS,2	    ; Si el valor de la bandera Z es 0 omite la inst. sig.
    clrf    zero	    ; Se pone en 0 la variable zero
    btfsc   STATUS, 2	    ; Si el valor de la bandera Z es 0 omite la inst. sig.
    call    ttmr0	    ; Se resetea el tmr0
    return