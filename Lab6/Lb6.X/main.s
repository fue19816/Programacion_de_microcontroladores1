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
; Creado: 23 mar, 2021
; última modificación: 28 mar, 2021

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
    movlw   247		    ; Se carga el valor 247 al registro para 2ms
    movwf   TMR0	    ;
    bcf	    T0IF	    ; Se coloca en 0 la bandera del tmr0
    endm
    
ttmr1 macro
    banksel PORTA	    ;
    movlw   0x0C	    ; Se carga el valor de 3110 al registro de tmr1
    movwf   TMR1H	    ;
    movlw   0x26	    ;
    movwf   TMR1L	    ;
    bcf	    TMR1IF	    ; Se coloca en 0 la bandera del tmr1
    endm
    
ttmr2 macro
    banksel PORTA	    ;
    clrf    TMR2	    ; Se limpia el registro del TMR2
    bcf	    TMR2IF	    ; Se coloca en 0 la bandera 
    endm
    
PSECT udata_bank0		;common memory
    cont:	        DS	    1	;1 byte
    cont1:		DS	    1	;1 byte
    cont2:		DS	    1	;1 byte
    var:		DS	    1	;1 byte
    varu:		DS	    1	;1 byte
    vard:		DS	    1	;1 byte
    display_var:	DS	    2	;2 byte
    banderas:		DS	    1	;1 byte

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
    btfsc   TMR1IF	    ;Se revisa si la bandera de overfl. de TMR1 esta enc
    call    int_t1	    ;Se llama la subrutina de interrupcion de TMR1
    btfsc   T0IF	    ;Se revisa si la bandera de overfl. de TMR0 esta enc
    call    int_t0	    ;Se llama la subrutina de interrupcion de TM
    btfsc   TMR2IF	    ;Se revisa si la bandera de overfl. de TMR2 esta enc
    call    int_t2	    ;Se realiza la subrutina del tmr2

pop:
    swapf   STATUS_TEMP, W  ;Se realiza nuevamente el swap de ST. Tem. para ST
    movwf   STATUS	    ;Se mueve el valor de W a ST
    movf    W_TEMP, W	    ;Se mueve el valor de W temp. a W  
    retfie

;----------------------subrutinas de interrupción-------------------------------
 int_t0:
    ttmr0			; Se resetea el TMR0
    clrf    PORTD		; Se limpia el puerto D
    btfss   banderas,0		; Se revisa si el bit 0 de banderas está enc.
    goto    display0		; Si no, se visualiza el display 0

    btfss   banderas,1		; Se revisa si el bit 1 de banderas está enc.
    goto    display1		; Si no, se visualiza el display 1 
    
display0:
    clrf    banderas		;Se limpia el registro de banderas
    bsf	    banderas,0		;Se coloca en 1 el bit menos significativo
    movf    display_var, 0	;Se mueve el valor de la variable a W
    movwf   PORTC		;Se mueve W al puerto C
    bsf	    PORTD, 0		;Se coloca en 1 el pin 0 del puerto D
    return
    
display1:
    bsf	    banderas,1		;Se coloca en 1 el segundo bit de banderas
    movf    display_var+1, 0	;Se mueve el valor de la variable  a W
    movwf   PORTC		;Se mueve W al puerto C
    bsf	    PORTD, 1		;Se coloca en 1 el pin 1 del puerto D
    return
    
int_t1:
    ttmr1		    ; Se reinicia el timer
    incf    cont1	    ; Se incrementa la variable cont1
    movf    cont1, 0	    ; Se mueve la variable cont a W
    sublw   2		    ; Se resta 2 al valor de W
    btfss   ZERO	    ; Si la resta no da 0
    return		    ; Regresa al las demás interrupciones
    clrf    cont1	    ; De lo contrario se pone en 0 la variable cont
    incf    cont	    ; Se incrementa la variable del contador    
    return
    
int_t2:
    ttmr2		    ;Se reinicia el timer 2
    incf    var		    ;
    movf    var, 0	    ;
    sublw   5		    ;Cada 4 conteos de 0.050 seg se realiza el cambio
    btfss   ZERO	    ;
    return		    ;
    clrf    var		    ;
    btfsc   PORTE, 0	    ;Revisa si está apagado el pin 0 del PORTE
    goto    apagar	    ;
    bsf	    PORTE, 0	    ;Si está apagado lo enciende
    return
    apagar:
    bcf	    PORTE, 0	    ;Si está encendido lo apaga
    return
;-----------------------tabla---------------------------------------------------
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
    clrf    cont	    ; La variable inicia en 0
    
    banksel TRISA	    ;
    clrf    TRISA	    ;
    clrf    TRISC	    ; Todos los pines de C son salida
    clrf    TRISD	    ; Todos los pines de D son salida
    clrf    TRISE	    ; Todos los pines de E son salida
   
    banksel PORTA	    ;
    clrf    PORTA	    ;
    clrf    PORTC	    ; El valor del puerto C inicia en 0
    clrf    PORTD	    ; El valor del puerto D inicia en 0
    clrf    PORTE	    ; El valor del puerto E inicia en 0
    
    call    config_reloj	    ; Se realiza la configuración del reloj
    call    config_tmr0		    ; Se realiza la configuración del TMR0
    call    config_tmr1		    ; Se realiza la configuración del TMR1
    call    config_tmr2		    ; Se realiza la configuración del TMR2
    call    config_int_enable	    ; Se realiza la habilitación de interr.
    
;-----------------------loop principal------------------------------------------
loop:
    btfss   PORTE, 0	    ; Se revisa si el led está encendido
    call    apag_displ	    ; Si no está encendido se apaga el display
    movf    cont, 0	    ; Se mueve el valor de la variable cont a cont2
    movwf   cont2	    ; 
    call    preparar_display; Se preparan los display
    call    div_dec	    ; Se llama a la subrutina de division por decena
    call    div_u	    ; Se llama a la subrutnia de division por unidad
    call    overf	    ; Se revisa si el contador llega a su límite
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
    
config_tmr1:
    banksel T1CON	    ;
    bsf	    TMR1ON	    ; Se enciende el timer 1
    bcf	    TMR1CS	    ; Se utiliza el oscilador interno
    bsf	    T1CKPS1	    ;
    bsf	    T1CKPS0	    ; Se utiliza un prescaler de 1:8
    ttmr1		    ; Se resetea el tmr1
    return
    
config_tmr2:
    banksel T2CON	    ;
    bsf	   TMR2ON	    ; Encender el tmr2
    bsf	   T2CKPS1	    ;
    bsf	   T2CKPS0	    ; prescaler de 1:16
    bsf	   TOUTPS3	    ;
    bsf	   TOUTPS2	    ;
    bsf	   TOUTPS1	    ;
    bsf	   TOUTPS0	    ; postcaler de 1:16
    banksel TRISA	    ; 
    movlw   196		    ; Se mueve el valor de 196 a PR2
    movwf   PR2		    ;
    ttmr2		    ;
    return

config_int_enable:
    bsf	    GIE		    ; INTCON
    bsf	    T0IE	    ; Se habilita la interrupción del timer 0
    bcf	    T0IF	    ; Se habilita la inte. cuando la bandera del TMR0
    bsf	    PEIE	    ; Se habilita las interrupciones de perifericos
    bsf	    TMR1IE	    ; Se habilita la interrupcion del timer 1
    bcf	    TMR1IF	    ; Se limpia la bandera del timer 1
    bsf	    TMR2IE	    ; Se habilita la interrupcion del timer 2
    bcf	    TMR2IF	    ; Se limpia la bandera del timer 2
    return
    
preparar_display:
    movf    vard, 0	    ;Se mueve el valor de vard a W
    call    tabla	    ;Se llama la tabla
    movwf   display_var	    ;Se guarda el valor de la tabla en display_var
    
    movf    varu,0	    ;Se mueve el valor de varu a W
    call    tabla	    ;Se llama la tabla
    movwf   display_var+1   ;Se guarda el valor de la tabla en display_var+1
    return
    
div_dec:
    clrf    vard	    ;Se limpia la variable a utilizar como cont
    movlw   10		    ;Se mueve el valor de 10 a W
    subwf   cont2, 0	    ;Se resta W al valor de la variable
    btfsc   CARRY	    ;Skip si la resta es negativa
    incf    vard	    ;Se incrementa la variable si la resta es positiva
    btfsc   CARRY	    ;Skip si la resta es negativa
    movwf   cont2	    ;Si la resta es positiva guarda el valor en la var.
    btfsc   CARRY	    ;Skip si la resta es negativa
    goto    $-7		    ;Si es positiva se vuelve a realizar el proced.
    return
    
div_u:
    clrf    varu	    ;Se limpia la variable a utilizar como cont
    movlw   1	    	    ;Se mueve el valor de 1 a W
    subwf   cont2, 0	    ;Se resta W al valor de la variable
    btfsc   CARRY	    ;Skip si la resta es negativa
    incf    varu	    ;Se incrementa la variable si la resta es positiva
    btfsc   CARRY	    ;Skip si la resta es negativa
    movwf   cont2	    ;Si la resta es positiva guarda el valor en la var.
    btfsc   CARRY	    ;Skip si la resta es negativa
    goto    $-7	   	    ;Si la resta es positiva realizar el proc. de nuevo
    return
    
overf:
    movlw   100		    ;Se mueve el valor de 100 a W
    subwf   cont, 0	    ;A W se le resta el valor de cont
    btfsc   CARRY	    ;Si la resta es negativa se salta la instrucc. sig.
    clrf    cont	    ;Si la resta es positiva se limpia la variable cont
    return
    
apag_displ:
    clrf    PORTC	    ;Se limpia el puerto C
    return
