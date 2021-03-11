; Archivo:     main.s
; Dispositivo: PIC16F8870
; Autor:       Oscar Fuentes
; Compilador:  pic-as (v2.30), MPLABX V5.45
;
; Programa:    Contador con pull ups y contador con tmr0
; Hardware:    LEDs en el puerto B y leds en el puerto A, display de 7 seg en el
;	       Puerto C y se controla el display mediante transistores en el
;	       Puerto D.
;
; Creado: 02 mar, 2021
; última modificación: 06 mar, 2021

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
    movlw   217		    ; Se carga el valor 217 al registro del tmr0 10ms
    movwf   TMR0	    ;
    bcf	    T0IF	    ; Se coloca en 0 la bandera del tmr0
    endm
    
PSECT udata_bank0		;common memory
    cont:	    DS	    1	;1 byte
    var1:	    DS	    1	;1 byte
    nibble:	    DS	    2	;2 byte
    display_var:    DS	    5	;5 byte
    banderas:	    DS	    1	;1 byte
    varB:	    DS	    1	;1 byte
    varc:	    DS	    1	;1 byte
    vard:	    DS	    1	;1 byte
    varu:	    DS	    1	;1 byte
    
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
    btfsc   T0IF	    ;Se revisa si la bandera de overflow de TMR0 esta enc.
    call    int_t0	    ; Se llama la subrutina de interrupcion de TMR0

pop:
    swapf   STATUS_TEMP, W  ; Se realiza nuevamente el swap de ST. Tem. para ST
    movwf   STATUS	    ; Se mueve el valor de W a ST
    movf    W_TEMP, W	    ; Se mueve el valor de W temp. a W  
    retfie
    
;-----------------------subrutina de interrupcion-------------------------------
int_t0:
    ttmr0			; Se resetea el TMR0
    clrf    PORTD		; Se limpia el puerto D
    btfss   banderas,0		; Se revisa si el bit 0 de banderas está encendido
    goto    display0		; Si no, se visualiza el display 0

    btfss   banderas,1		; Se revisa si el bit 1 de banderas está encendido
    goto    display1		; Si no, se visualiza el display 1 
    
    btfss   banderas,2		;Se revisa si el bit 2 de banderas está encendido
    goto    display2		; Si no, se visualiza el display 2
    
    btfss   banderas,3		;Se revisa si el bit 3 de banderas está encendido
    goto    display3		;Si no, se visualiza el display 3
    
    btfss   banderas,4		;Se revisa si el bit 4 de banderas está encendido
    goto    display4		;Si no, se visualiza el display 4
    
display0:
    clrf    banderas		;Se limpia el registro de banderas
    bsf	    banderas,0		;Se coloca en 1 el bit menos significativo
    movf    display_var, 0	;Se mueve el valor de la variable display_var a W
    movwf   PORTC		;Se mueve W al puerto C
    bsf	    PORTD, 0		;Se coloca en 1 el pin 0 del puerto D
    return
    
display1:
    bsf	    banderas,1		;Se coloca en 1 el segundo bit de banderas
    movf    display_var+1, 0	;Se mueve el valor de la variable display_var+1 a W
    movwf   PORTC		;Se mueve W al puerto C
    bsf	    PORTD, 1		;Se coloca en 1 el pin 1 del puerto D
    return
    
display2:
    bsf	    banderas,2		;Se coloca en 1 el tercer bit de banderas
    movf    display_var+2, 0	;Se mueve el valor de la variable display_var+2 a W
    movwf   PORTC		;Se mueve W al puerto C
    bsf	    PORTD, 2		;Se coloca en 1 el pin 2 del puerto D
    return
    
display3:
    bsf	    banderas,3		;Se coloca en 1 el cuarto bit de banderas
    movf    display_var+3, 0	;Se mueve el valor de la variable display_var+3 a W
    movwf   PORTC		;Se mueve W al puerto C
    bsf	    PORTD, 3		;Se coloca en 1 el pin 3 del puerto D
    return  
    
display4:
    bsf	    banderas,4		;Se coloca en 1 el quinto bit de banderas
    movf    display_var+4, 0	;Se mueve el valor de la variable display_var+3 a W
    movwf   PORTC		;Se mueve W al puerto C
    bsf	    PORTD, 4		;Se coloca en 1 el pin 4 del puerto D
    return
  
int_intonch:
    banksel	PORTA	    ; 
    btfss	PORTB, 1    ; Revisa si el pin 1 esta encendido, si no es así
    decf	PORTA	    ; Decremento el puerto A
    btfss	PORTB, 0    ; Revisa si el pin 0 está encendido, si no es así
    incf	PORTA	    ; Incremento el puerto A
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
    clrf    varB	    ; Se limpia la variable varB
    
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
    
    call    config_reloj	    ; Se realiza la configuración del reloj
    call    config_tmr0		    ; Se realiza la configuración del TMR0
    call    config_int_enable	    ; Se realiza la habilitación de interr.
    call    config_intonch	    ; Se configura la interrpcion de los puertos B
;-----------------------loop principal------------------------------------------
loop:
    call    separar_nibbles ; Se llama a la subrutina que separa los nibbles
    call    preparar_display; Se prepara el display
    movf    PORTA,  0	    ; Se mueve el valor de PORTA a W
    movwf   varB	    ; Se mueve el valor de W a varB
    call    div_cent	    ; Se llama a la subrutina de division por centena
    call    div_dec	    ; Se llama a la subrutina de division por decena
    call    div_u	    ; Se llama a la subrutnia de division por unidad
    goto    loop
    
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

config_int_enable:
    bsf	    GIE		    ; INTCON
    bsf	    T0IE	    ; Se habilita la interrupción del timer 0
    bcf	    T0IF	    ; Se habilita la interrupción cuando la bandera del TMR0
    bsf	    RBIE	    ; Se habilita la interrupción del puerto B
    bcf	    RBIF	    ; Se habilita la iinterrupción cuando el puerto B,
			    ; cuando esta recibe un cambio			    
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
    
separar_nibbles:
    movf    PORTA, 0	    ;Se toma el valor del PORTB y se mueve a W
    andlw   0x0f	    ;Se realiza un AND con 0x0F
    movwf   nibble	    ;El valor se guarda en la variable nibble
    
    swapf   PORTA, 0	    ;El valor de PORTB, se inter. los nibb. y se mueve a W
    andlw   0x0f	    ;Se realiza un AND con 0x0F
    movwf   nibble+1	    ;El valor se guarda en la variable nibble+1
    return
    
preparar_display:
    movf    nibble, 0	    ;Se mueve el valor de nibble a W
    call    tabla	    ;Se llama la tabla
    movwf   display_var	    ;Se guarda el valor de la tabla en display_var
    
    movf    nibble+1, 0	    ;Se mueve el valor de nibble+1 a W
    call    tabla	    ;Se llama la tabla
    movwf   display_var+1   ;Se guarda el valor de la tabla en display_var+1
    
    movf    varc, 0	    ;Se mueve el valor de varc a W
    call    tabla	    ;Se llama la tabla
    movwf   display_var+2   ;Se guarda el valor de la tabla en display_var+2
    
    movf    vard, 0	    ;Se mueve el valor de vard a W
    call    tabla	    ;Se llama la tabla
    movwf   display_var+3   ;Se guarda el valor de la tabla en display_var+3
    
    movf    varu,0	    ;Se mueve el valor de varu a W
    call    tabla	    ;Se llama la tabla
    movwf   display_var+4   ;Se guarda el valor de la tabla en display_var+4
    return
    
div_cent:
    clrf    varc	    ; Se limpia la variable a utilizar como cont
    movlw   100		    ; Se mueve el valor de 100 a W
    subwf   varB, 0	    ; Se resta W al valor de la variable
    btfsc   CARRY	    ; Skip si la resta es negativa
    incf    varc	    ; Si la resta es positiva se incrementa la variable
    btfsc   CARRY	    ; Skip si la resta es negativa
    movwf   varB	    ; Si la resta es positiva se guarda el valor en la var.
    btfsc   CARRY	    ; Skip si la resta es negativa
    goto    $-7		    ; Si es positiva se vuelve a realizar el proced.
    return
    
div_dec:
    clrf    vard	    ; Se limpia la variable a utilizar como cont
    movlw   10		    ; Se mueve el valor de 10 a W
    subwf   varB, 0	    ; Se resta W al valor de la variable
    btfsc   CARRY	    ; Skip si la resta es negativa
    incf    vard	    ; Se incrementa la variable si la resta es positiva
    btfsc   CARRY	    ; Skip si la resta es negativa
    movwf   varB	    ; Si la resta es positiva se guarda el valor en la var.
    btfsc   CARRY	    ; Skip si la resta es negativa
    goto    $-7		    ; Si es positiva se vuelve a realizar el procedimiento
    return
    
div_u:
    clrf    varu	    ; Se limpia la variable a utilizar como cont
    movlw   1	    	    ; Se mueve el valor de 1 a W
    subwf   varB, 0	    ; Se resta W al valor de la variable
    btfsc   CARRY	    ; Skip si la resta es negativa
    incf    varu	    ; Se incrementa la variable s la resta es positiva
    btfsc   CARRY	    ; Skip si la resta es negativa
    movwf   varB	    ; Si la resta es positiva se guarda el valor en la var.
    btfsc   CARRY	    ; Skip si la resta es negativa
    goto    $-7	   	    ; Si la resta es positiva se vuelve a realizar el proc.
    return