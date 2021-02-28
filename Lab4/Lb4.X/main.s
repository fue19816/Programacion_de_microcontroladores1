; Archivo:     main.s
; Dispositivo: PIC16F8870
; Autor:       Oscar Fuentes
; Compilador:  pic-as (v2.30), MPLABX V5.45
;
; Programa:    Contador con pull ups y contador con tmr0
; Hardware:    LEDs en el puerto A y botones en el puerto B, display de 7 seg
;	       en el puerto C y D y push en RB0 Y RB1
;
; Creado: 23 feb, 2021
; última modificación: 27 feb, 2021

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
    
ttmr0 macro
    banksel PORTA	    ;
    movlw   61		    ; Se carga el valor 61 al registro del tmr0
    movwf   TMR0	    ;
    bcf	    T0IF	    ; Se coloca en 0 la bandera del tmr0
    endm
    
int_t0 macro
    ttmr0		    ; Se reinicia el timer
    incf    cont	    ; Se incrementa la variable cont
    movf    cont, 0	    ; Se mueve la variable cont a W
    sublw   20		    ; Se resta 20 al valor de W
    btfss   ZERO	    ; Si la resta no da 0
    goto    pop		    ; Se mueve a la interrupcion pop
    clrf    cont	    ; De lo contrario se pone en 0 la variable cont
    incf    var1	    ; Se incrementa la variable del contador 1
    endm
    
PSECT udata_bank0		;common memory
    cont: DS 1			;1 byte
    var1: DS 1			;1 byte
    
PSECT udata_shr		;common memory
    W_TEMP:	    DS	    1
    STATUS_TEMP:    DS	    1
    

  PSECT resVect, class=CODE, abs, delta=2
 ;-----------vector reset-------------------------------------------------------
 ORG 00h		;posición 0000h para el reset
 resetVec:
    PAGESEL main
    goto main
    
 PSECT inVect, class=CODE, abs, delta=2
;---------------------interrupt vector------------------------------------------
 ORG 04h		    ;posición 0004h para las interrupciones
 push:
    movwf   W_TEMP	    ;Se mueve el valor de W a una W temporal
    swapf   STATUS, W	    ;Se realiza el swap para guardar las banderas de ST
    movwf   STATUS_TEMP	    ;Se mueve el valor del swap a un STATUS temporal

 isr:
    btfsc   RBIF	    ;Se revisa si la bandera que registra un cambio está apag.
    call    int_intonch	    ;Se llama la subrutina de interrupción del puerto B
    btfsc   T0IF	    ;Se revisa si la bandera del TMR0 está apagagada
    int_t0		    ;Se llama el macro de interrupción del TMR0

pop:
    swapf   STATUS_TEMP, W  ; Se realiza nuevamente el swap de ST. Tem. para ST
    movwf   STATUS	    ; Se mueve el valor de W a ST
    movf    W_TEMP, W	    ; Se mueve el valor de W temp. a W  
    retfie
    
;-----------------------subrutina de interrupcion-------------------------------
int_intonch:
    banksel	PORTA	    ; 
    btfss	PORTB, 1    ; Revisa si el pin 1 esta encendido, si no es así
    incf	PORTA	    ; Incrementa el puerto A
    btfss	PORTB, 0    ; Revisa si el pin 0 está encendido, si no es así
    decf	PORTA	    ; Decrementa el puerto A
    bcf		RBIF	    ; Se pone en 0 la bandera que registra cambio en B
    return

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
    
;----------------------configuración--------------------------------------------
 main:
    banksel ANSEL	    ;
    clrf    ANSEL	    ; Las entradas/salidas del puerto A son digitales
    clrf    ANSELH	    ; Las entradas/salidas del puerto B son digitales
    clrf    var1	    ; La variable inicia en 0
    
    banksel TRISA	    ;
    clrf    TRISA	    ; Todos los pines de A son salida
    movlw   11111111B	    ; Todos los pines de B son entrada
    movwf   TRISB	    ;
    clrf    TRISC	    ; Todos los pines de C son salida
    clrf    TRISD	    ; Todos los pines de D son salida
    bcf	    OPTION_REG, 7   ; RBPU se habilita los pull-up del puerto B
    bsf	    WPUB, 0	    ; Se habilita el pull-up del pin 0 del puerto B
    bsf	    WPUB, 1	    ; Se habilita el pull-up del pin 1 del puerto B
    
    banksel PORTA	    ;
    clrf    PORTA	    ; El valor del puerto A inicia en 0
    clrf    PORTC	    ; El valor del puerto C inicia en 0
    clrf    PORTD	    ; El valor del puerto D inicia en 0
    
    call    config_reloj	    ;
    call    config_tmr0		    ;
    call    config_intonch	    ;
    call    config_int_enable	    ;
;-----------------------loop principal------------------------------------------
loop:
    call    cont_hex1	    ; Se llama la subrutina encargada del contador 1 hex
    movf    var1, 0	    ; Se llama el valor registrado en var1 y se mueve a W
    call    tabla	    ; Se llama la tabla
    movwf   PORTD	    ; Se mueve el valor llamado por la tabla al puerto D
    goto loop
    
;------------------------sub rutinas--------------------------------------------
config_reloj:
    banksel OSCCON	    ;
    bsf	    IRCF2	    ;
    bsf	    IRCF1	    ;
    bcf	    IRCF0	    ; Se configura el IRCF a 110, que son 4MHz de clk
    bsf	    SCS		    ; Se utiliza el oscilador interno para el clk
    return

config_tmr0:
    banksel TRISA	    ;
    bcf	    T0CS	    ; Se utiliza el ciclo de reloj interno
    bcf	    PSA		    ;
    bsf	    PS2		    ;
    bsf	    PS1		    ;
    bsf	    PS0		    ; El valor del prescaler es 111 lo que es 1:256
    ttmr0		    ; Se llama al macro de reinicio del tmr0
    return
    
config_intonch:
    banksel	TRISA	    ;
    bsf		IOCB, 0	    ; Se habilita la interupción de cambio en el pin 0
			    ; del puerto B
    bsf		IOCB, 1	    ; Se habilita la interrupcion de cambio en el pin 1
			    ; del puerto B
    banksel   PORTA	    ;
    movf      PORTB,  W	    ; Al leer termina condición de mismatch
    bcf	      RBIF	    ; Se limpia la bandera que registra el cambio en un
			    ; de los puertos
    return

config_int_enable:
    bsf	    GIE		    ; INTCON
    bsf	    RBIE	    ; Se habilita la interrupción del puerto B
    bcf	    RBIF	    ; Se habilita la iinterrupción cuando el puerto B,
			    ; cuando esta recibe un cambio
    bsf	    T0IE	    ; Se habilita la interrupción del timer 0
    bcf	    T0IF	    ; Se habilita la interrupción cuando la bandera del
			    ; timer 0
    return
    
cont_hex1:
    movf    PORTA, 0	    ; Se mueve el valor del puerto A a W
    call    tabla	    ; Se llama a la tabla de los valores hexadecimal
    movwf   PORTC	    ; Se mueve el valor dado por la tabla al puerto C
    return