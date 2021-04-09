; Archivo:     main.s
; Dispositivo: PIC16F8870
; Autor:       Oscar Fuentes
; Compilador:  pic-as (v2.30), MPLABX V5.45
;
; Programa:    Contador con pull ups y contador con tmr1
; Hardware:    LEDs en PORTD, botones en PORTB, transistores en PORTA y display
;	       7 segmentos en PORTC
;
; Creado: 31 mar, 2021
; última modificación: 05 abr, 2021

; Assembly source line config statements

PROCESSOR 16F887 
#include <xc.inc>

; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscilador interno
  CONFIG  WDTE = OFF            ; Watchdog Timer apagado
  CONFIG  PWRTE = ON            ; Power-up Timer apagado
  CONFIG  MCLRE = OFF           ; RE3/MCLR apagado
  CONFIG  CP = OFF              ; Code Protection bit apagado
  CONFIG  CPD = OFF             ; Data Code Protection bit apagado
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Cmabio de oscilador apagado
  CONFIG  FCMEN = OFF           ; Seguro del monitor apagado
  CONFIG  LVP = ON              ; Programación a bajo voltaje encendido

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Reseteo si baja de 4V
  CONFIG  WRT = OFF             ;Escritura propia de la FLASH MEMORY RAM apagado

ttmr0 macro
    banksel PORTA	    ;
    movlw   254		    ; Se carga el valor 254 al registro para 2ms
    movwf   TMR0	    ;
    bcf	    T0IF	    ; Se coloca en 0 la bandera del tmr0
    endm
    
ttmr1 macro
    banksel PORTA	    ;
    movlw   0x85	    ; Se carga el valor de 34286 al registro de tmr1
    movwf   TMR1H	    ;
    movlw   0xEE	    ;
    movwf   TMR1L	    ;
    bcf	    TMR1IF	    ; Se coloca en 0 la bandera del tmr1
    endm
    
div_dec macro arg1, arg2
    clrf    arg1	    ;Se limpia la variable a utilizar como cont
    movlw   10		    ;Se mueve el valor de 10 a W
    subwf   arg2, 0	    ;Se resta W al valor de la variable
    btfsc   CARRY	    ;Skip si la resta es negativa
    incf    arg1	    ;Se incrementa la variable si la resta es positiva
    btfsc   CARRY	    ;Skip si la resta es negativa
    movwf   arg2	    ;Si la resta es positiva guarda el valor en la var.
    btfsc   CARRY	    ;Skip si la resta es negativa
    goto    $-7		    ;Si es positiva se vuelve a realizar el proced.
    endm
    
div_u macro arg1, arg2
    clrf    arg1	    ;Se limpia la variable a utilizar como cont
    movlw   1	    	    ;Se mueve el valor de 1 a W
    subwf   arg2, 0	    ;Se resta W al valor de la variable
    btfsc   CARRY	    ;Skip si la resta es negativa
    incf    arg1	    ;Se incrementa la variable si la resta es positiva
    btfsc   CARRY	    ;Skip si la resta es negativa
    movwf   arg2	    ;Si la resta es positiva guarda el valor en la var.
    btfsc   CARRY	    ;Skip si la resta es negativa
    goto    $-7	   	    ;Si la resta es positiva realizar el proc. de nuevo
    endm
    
prep_display macro arg1, arg2
    movf    arg1, 0
    call    tabla
    movwf   arg2
    endm
    
overflow macro vari
    movlw   21		    ;Se mueve el valor de 20 a W
    subwf   vari, 0	    ;A W se le resta el valor de cont
    btfsc   ZERO	    ;Si la resta es negativa se salta la instrucc. sig.
    movlw   10		    ;
    btfsc   ZERO	    ;
    movwf   vari	    ;
    movlw   9		    ;
    subwf   vari, 0	    ;
    btfsc   ZERO	    ;
    movlw   20		    ;
    btfsc   ZERO	    ;
    movwf   vari	    ; overflow de las variables var, var2 y var3
    endm
    
PSECT udata_bank0		;common memory
    cont:	        DS	    1	;1 byte
    cont2:		DS	    1	;1 byte
    cont3:		DS	    1	;1 byte
    estado:		DS	    1	;1 byte
    verde:		DS	    1	;1 byte
    amarillo:		DS	    1	;1 byte
    rojo:		DS	    1	;1 byte
    temp:		DS	    1	;1 byte
    temp1:		DS	    1	;1 byte
    temp2:		DS	    1	;1 byte
    prim_vez:		DS	    1	;1 byte
    var:		DS	    1	;1 byte
    var2:		DS	    1	;1 byte
    var3:		DS	    1	;1 byte
    vd:			DS	    1	;1 byte
    vd1:		DS	    1	;1 byte
    vd2:		DS	    1	;1 byte
    vd3:		DS	    1	;1 byte
    vard:		DS	    1	;1 byte
    varu:		DS	    1	;1 byte
    varu1:		DS	    1	;1 byte
    vard1:		DS	    1	;1 byte
    varu2:		DS	    1	;1 byte
    vard2:		DS	    1	;1 byte
    varu3:		DS	    1	;1 byte
    vard3:		DS	    1	;1 byte
    verde_t:		DS	    1	;1 byte
    tit_verd:		DS	    1	;1 byte
    display_var:	DS	    8	;8 bytes
    banderas:		DS	    1	;1 byte
    rein:		DS	    1	;1 byte

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
    btfsc   RBIF	    ;Se revisa si se presionó un botón
    call    int_b	    ;Si es así se llama a la interrupción del botón
    btfsc   TMR1IF	    ;Se revisa si el timer 1 posee overflow
    call    int_tmr1	    ;Si es así se llama a su interrupción
    btfsc   T0IF	    ;Se revisa si el timer 0 posee overflow
    call    int_tmr0	    ;Si es así se llama a su interrupcion

pop:
    swapf   STATUS_TEMP, W  ;Se realiza nuevamente el swap de ST. Tem. para ST
    movwf   STATUS	    ;Se mueve el valor de W a ST
    movf    W_TEMP, W	    ;Se mueve el valor de W temp. a W  
    retfie
;----------------------subrutinas de interrupción-------------------------------
int_b:
    btfss   PORTB, 0	    ;Se revisa si se presiono el primer boton
    incf    estado	    ;Si es así, se incrementa el valor de estado
    
    movlw   4		    ;Se revisa cual es el valor exacto de estado
    subwf   estado, 0	    ;
    btfsc   CARRY	    ;
    goto    esta4	    ;Si es cuatro se va a la etiqueta esta4

    movlw   3		    ;		
    subwf   estado, 0	    ;
    btfsc   CARRY	    ;
    goto    esta3	    ;Si es tres se va a la etiqueta esta3
    
    movlw   2		    ;
    subwf   estado, 0	    ;
    btfsc   CARRY	    ;
    goto    esta2	    ;Si es 2 se va a la etique esta2
    
    movlw   1		    ;
    subwf   estado, 0	    ;
    btfsc   CARRY	    ;
    goto    esta1	    ;Si es 1 se va a la etiqueta esta 1
    
    bcf	    RBIF	    ;En caso que el valor sea 0 o mas de 4 se termina
    return		    ;la interrupción
    
    esta4:
    btfss   PORTB, 1	    ;En el estado 4, si se presiona el botón 2
    goto    aceptar	    ;Se acepta los nuevos cambios
    btfss   PORTB, 2	    ;Si se presiona el botón 3, se cancelan los cambios
    incf    estado	    ;
    bcf	    RBIF
    return
    
    aceptar:
    movf    var3, 0	    ;Las variables que se incrementaron en cada uno de
    movwf   temp2	    ;los estados se almacenan al valor del temporizador
    movf    var2, 0	    ;de cada uno de los semaforos
    movwf   temp1	    ;
    movf    var, 0	    ;
    movwf   temp	    ;
    clrf    estado	    ;Se limpia el valor de estado, para que este sea 0
    clrf    verde	    ;Se limpia el registro verde
    clrf    amarillo	    ;Se limpia el registro amarillo
    clrf    rojo	    ;Se limpia el registro rojo
    bcf	    RBIF	    ;
    bsf	    rein, 0	    ;Se pone en 1 la bandera de reinicio
    return
    
    esta3:
    btfss   PORTB, 1	    ;En el estado 3, si se presiona el boton 2 se incr.
    incf    var3	    ;la variable 3, perteneciente al semaforo 3
    btfss   PORTB, 2	    ;Si se presiona el boton 3, se decrementa
    decf    var3	    ;
    bcf	    RBIF
    return
    
    esta2:
    btfss   PORTB, 1	    ;En el estado 2, si se presiona el boton 2 se incr.
    incf    var2	    ;la variable 2, perteneciente al semaforo 2
    btfss   PORTB, 2	    ;Si se presiona el boton 3, se decrementa
    decf    var2	    ;
    bcf	    RBIF
    return
    
    esta1:
    btfss   PORTB, 1	    ;En el estado 1, si se presiona el boton 2 se incr.
    incf    var		    ;la variable 1, perteneciente al semaforo 1
    btfss   PORTB, 2	    ;Si se presiona el boton 3, se decrementa
    decf    var		    ;
    bcf	    RBIF    
    return
    
int_tmr1:
    ttmr1
    decf    cont	    ;Por cada segundo se va decrementando el valor de
    decf    cont2	    ;cada uno de los semaforos
    decf    cont3	    ;
    
    btfsc   rein, 1	    ;Si la 2da bandera de reinicio está encendida 
    goto    limpiar	    ;Se limpia dicha bandera (despues de 1 segundo)
    bsf	    rein, 1	    ;Si está apagada, se enciende
    goto    verde_tit	    ;
    limpiar:
    bcf	    rein, 1	    ;
    verde_tit:
    btfsc   tit_verd, 0	 ;Se revisa si está en 1 la bandera de verde tit. del
    goto    titilar1	 ;semaforo 1. Si es así se llama a la subr. de titilar.
    btfsc   tit_verd, 1	 ;Se revisa si está en 1 la bandera de verde tit. del
    goto    titilar2	 ;semaforo 2. Si es así se llama a la subr. de titilar.
    btfsc   tit_verd, 2	 ;Se revisa si está en 1 la bandera de verde tit. del
    goto    titilar3	 ;semaforo 3. Si es así se llama a la subr. de titilar.
    return
    
    titilar1:
    btfss   PORTD, 2	;Se revisa si está encendido el led, si es así se apaga,
    goto    encender	;si no se enciende
    bcf	    PORTD, 2	;
    return
    encender:
    bsf	    PORTD, 2	;
    return
    
    titilar2:
    btfss   PORTD, 5	;Se revisa si está encendido el led, si es así se apaga,
    goto    encender2	;si no se enciende
    bcf	    PORTD, 5	;
    return
    encender2:
    bsf	    PORTD, 5	;
    return
    
    titilar3:
    btfss   PORTB, 7	;Se revisa si está encendido el led, si es así se apaga,
    goto    encender3	;si no se enciende
    bcf	    PORTB, 7	;
    return
    encender3:
    bsf	    PORTB, 7	;
    return
    
int_tmr0:
    ttmr0			;Se resetea el TMR0
    clrf    PORTA		;Se limpia el puerto A
    btfss   banderas,0		;Se revisa si el bit 0 de banderas está encen.
    goto    display0		;Si no, se visualiza el display 0

    btfss   banderas,1		;Se revisa si el bit 1 de banderas está encen.
    goto    display1		;Si no, se visualiza el display 1 
    
    btfss   banderas,2		;Se revisa si el bit 2 de banderas está encen.
    goto    display2		;Si no, se visualiza el display 2
    
    btfss   banderas,3		;Se revisa si el bit 3 de banderas está encen.
    goto    display3		;Si no, se visualiza el display 3
    
    btfss   banderas,4		;Se revisa si el bit 4 de banderas está encen.
    goto    display4		;Si no, se visualiza el display 4
    
    btfss   banderas,5		;Se revisa si el bit 4 de banderas está encen.
    goto    display5		;Si no, se visualiza el display 5
    
    btfss   banderas,6		;Se revisa si el bit 4 de banderas está encen.
    goto    display6		;Si no, se visualiza el display 6
    
    btfss   banderas,7		;Se revisa si el bit 4 de banderas está encen.
    goto    display7		;Si no, se visualiza el display 7
    
display0:
    clrf    banderas		;Se limpia el registro de banderas
    bsf	    banderas,0		;Se coloca en 1 el bit menos significativo
    movf    display_var, 0	;Se mueve el valor de display_var a W
    movwf   PORTC		;Se mueve W al puerto C
    bsf	    PORTA, 1		;Se coloca en 1 el pin 0 del puerto D
    return
    
display1:
    bsf	    banderas,1		;Se coloca en 1 el segundo bit de banderas
    movf    display_var+1, 0	;Se mueve el valor de  display_var+1 a W
    movwf   PORTC		;Se mueve W al puerto C
    bsf	    PORTA, 0		;Se coloca en 1 el pin 1 del puerto D
    return
    
display2:
    bsf	    banderas,2		;Se coloca en 1 el tercer bit de banderas
    movf    display_var+2, 0	;Se mueve el valor de  display_var+2 a W
    movwf   PORTC		;Se mueve W al puerto C
    bsf	    PORTA, 3		;Se coloca en 1 el pin 2 del puerto D
    return
    
display3:
    bsf	    banderas,3		;Se coloca en 1 el cuarto bit de banderas
    movf    display_var+3, 0	;Se mueve el valor de  display_var+3 a W
    movwf   PORTC		;Se mueve W al puerto C
    bsf	    PORTA, 2		;Se coloca en 1 el pin 3 del puerto D
    return  
    
display4:
    bsf	    banderas,4		;Se coloca en 1 el quinto bit de banderas
    movf    display_var+4, 0	;Se mueve el valor de  display_var+3 a W
    movwf   PORTC		;Se mueve W al puerto C
    bsf	    PORTA, 5		;Se coloca en 1 el pin 4 del puerto D
    return
    
display5:
    bsf	    banderas,5		;Se coloca en 1 el quinto bit de banderas
    movf    display_var+5, 0	;Se mueve el valor de display_var+3 a W
    movwf   PORTC		;Se mueve W al puerto C
    bsf	    PORTA, 4		;Se coloca en 1 el pin 4 del puerto D
    return
    
display6:
    bsf	    banderas,6		;Se coloca en 1 el quinto bit de banderas
    movf    display_var+6, 0	;Se mueve el valor de display_var+3 a W
    movwf   PORTC		;Se mueve W al puerto C
    bsf	    PORTA, 7		;Se coloca en 1 el pin 4 del puerto D
    return
    
display7:
    bsf	    banderas,7		;Se coloca en 1 el quinto bit de banderas
    movf    display_var+7, 0	;Se mueve el valor de display_var+3 a W
    movwf   PORTC		;Se mueve W al puerto C
    bsf	    PORTA, 6		;Se coloca en 1 el pin 4 del puerto D
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
    
    banksel TRISA	    ;
    clrf    TRISA	    ;
    movlw   01111111B	    ; Todos los pines de B son entradas, menos el ult.
    movwf   TRISB	    ;
    clrf    TRISC	    ; Todos los pines de C son salida
    clrf    TRISD	    ; Todos los pines de D son salida
    clrf    TRISE	    ;
    bcf	    OPTION_REG, 7   ; RBPU se habilita los pull-up del puerto B
    bsf	    WPUB, 0	    ; Se habilita el pull-up del pin 0 del puerto B
    bsf	    WPUB, 1	    ; Se habilita el pull-up del pin 1 del puerto B
    bsf	    WPUB, 2	    ;
   
    banksel PORTA	    ;
    clrf    PORTA	    ; El valor del puerto A inicia en 0
    clrf    PORTC	    ; El valor del puerto C inicia en 0
    clrf    PORTD	    ; El valor del puerto D inicia en 0
    clrf    PORTE	    ;
    
    clrf    verde	    ;Se limpian todos los registros a usar como bandera
    clrf    amarillo	    ;
    clrf    rojo	    ;
    clrf    estado	    ;
    clrf    prim_vez	    ;
    clrf    verde_t	    ;
    clrf    tit_verd	    ;
    
    movlw   10			    ;Se mueve el valor de 10 a cada una de las
    movwf   var			    ;variables de cada uno de los semaforos
    movlw   10			    ;
    movwf   var2		    ;
    movlw   10			    ;
    movwf   var3		    ;
    
    movlw   10			    ;Se mueve el valor de 10 a cada una de los 
    movwf   temp		    ;temporizadores de los semaforos
    movlw   10			    ;
    movwf   temp1		    ;
    movlw   10			    ;
    movwf   temp2		    ;
    
    call    config_reloj	    ; Se realiza la configuración del reloj
    call    config_tmr0		    ; Se realiza la configuración del TMR0
    call    config_tmr1		    ; Se realiza la configuración del TMR1
    call    config_int_enable	    ; Se realiza la habilitación de interr.
    call    config_intonch	    ; Se realiza la config. de la inter. de bot.
;-----------------------loop principal------------------------------------------
loop:
    btfsc   rein, 0	    ;Se revisa si está encendida la bandera de reinicio
    call    reinicio	    ;Si es así, se llama a la subr. de reinicio
    
    movlw   4		    ;Se verifica el estado en el que se encuentra el
    subwf   estado, 0	    ;microcontrolador.
    btfsc   ZERO	    ;
    call    estado4	    ;
    movlw   3		    ;
    subwf   estado, 0	    ;
    btfsc   ZERO	    ;
    call    estado3	    ;
    movlw   2		    ;
    subwf   estado, 0	    ;
    btfsc   ZERO	    ;
    call    estado2	    ;
    movlw   1		    ;
    subwf   estado, 0	    ;
    btfsc   ZERO	    ;
    call    estado1	    ;
    movf    estado, 0	    ;
    btfsc   ZERO	    ;
    call    estado0	    ;
    
;Semaforo 1
    btfss   verde, 0	;Se observa si la bandera de verde del 1er semaforo
    call    verde1	;está encendida, si no es así se llama al estado verde
    movf    cont, 0	;Se verifica el valor del contador
    btfsc   ZERO	;Si es igual a cero
    call    amarillo1	;Se llama a la subrutina de amarillo
    movf    cont, 0	;
    btfsc   ZERO	;Se revisa si está en 0 nuevamente
    call    rojo1	;Si esta en amarillo se pasa a rojo
    movf    cont, 0	;
    btfsc   ZERO	;
    call    reinicio1	;Se vuelve a verde nuevamente
    
    call    verde_tit1	;Si el semaforo está en verde se llama a la subr. de 
			;verde titilante
    
;Semaforo 2
    btfss   rojo, 1	;Se verifica si el semaforo ya estaba en rojo
    call    rojo2	;Si no es así, se pone en rojo
    movf    cont2, 0	;Se revisa si el contador es igual a 0
    btfsc   ZERO	;Si es así
    call    verde2	;Se llama a la subrutina de verde
    movf    cont2, 0	;
    btfsc   ZERO	;Se verifica nuevamente si es igual a 0
    call    amarillo2	;Si es así, se llama a la subr. de amarillo
    movf    cont2, 0	;
    btfsc   ZERO	;Se verifica nuevamente si es igual a 0
    call    reinicio2	;Si es así el semaforo vuelve a rojo
    
    call    verde_tit2	;Si el semaforo 2 está en verde, se llama a la subr.
			;de semaforo verde
    
;Semaforo 3
    btfss   rojo, 2	;Se verifica si el semaforo ya estaba en rojo
    call    rojo3	;Si no es así, se pone en rojo
    movf    cont3, 0	;Se revisa si el contador es igual a 0
    btfsc   ZERO	;Si es así
    call    verde3	;Se llama a la subrutina de verde
    movf    cont3, 0	;
    btfsc   ZERO	;Se verifica nuevamente si es igual a 0
    call    amarillo3	;Si es así, se llama a la subr. de amarillo
    movf    cont3, 0	;
    btfsc   ZERO	;Se verifica nuevamente si es igual a 0
    call    reinicio3	;Si es así el semaforo vuelve a rojo
    
    call    verde_tit3	;Si el semaforo 2 está en verde, se llama a la subr.
			;de semaforo verde
    
    movf    cont, 0	    ;Se mueve el valor de cont a vd1 (semaforo 1)
    movwf   vd1		    ;
    movf    cont2, 0	    ;Se mueve el valor de cont2 a vd2 (semaforo 2)
    movwf   vd2		    ;
    movf    cont3, 0	    ;Se mueve el valor de cont3 a vd3 (semaforo 3)
    movwf   vd3		    ;
    
    div_dec  vard,vd	    ;Cada una de las variables de vd, se divide en 
    div_dec  vard1,vd1	    ;decena y unidad
    div_dec  vard2,vd2	    ;
    div_dec  vard3,vd3	    ;El valor vd, representa el valor de la variable
    div_u    varu, vd	    ;de cada uno de los semaforos, mientras se está
    div_u    varu1, vd1	    ;configurando
    div_u    varu2, vd2	    ; 
    div_u    varu3, vd3	    ;
    
    call    preparar_display ; Se preparan los display
    overflow var	     ;Se revisa si hay over. o subov. en cada una de las
    overflow var2	     ;variables
    overflow var3	     ;
    call    overf	    ; Se revisa si estado llega a su límite
    goto    loop
    
;------------------------sub rutinas--------------------------------------------
config_reloj:
    banksel OSCCON	    ;
    bsf	    IRCF2	    ;
    bcf	    IRCF1	    ;
    bcf	    IRCF0	    ; Se configura el IRCF a 100, que son 1MHz de clk
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
    
config_intonch:
    banksel	TRISA	    ;
    bsf		IOCB, 0	    ; Se habilita la interupción de cambio en el pin 0
			    ; del puerto B
    bsf		IOCB, 1	    ; Se habilita la interrupcion de cambio en el pin 1
			    ; del puerto B
    bsf		IOCB, 2	    ;
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
    bcf	    T0IF	    ; Se habilita la inte. cuando la bandera del TMR0
    bsf	    PEIE	    ; Se habilita las interrupciones de perifericos
    bsf	    TMR1IE	    ; Se habilita la interrupcion del timer 1
    bcf	    TMR1IF	    ; Se limpia la bandera del timer 1
    return
    
estado4:
    bsf	    PORTE, 0	    ;Se encienden los leds que marca que está en el 
    bsf	    PORTE, 1	    ;estado 4 y si se quiere cancelar o aceptar los 
    bsf	    PORTE, 2	    ;cambios en cada uno de los semaforos
    return
    
verde1:
    btfsc   verde, 0	    ;Se revisa si está encendida la bandera verde del
    return		    ;semaforo 1
    movf    temp, 0	    ;Si no es así, se mueve el valor del temporizador
    movwf   cont	    ;al valor del contador del semaforo 1
    bsf	    verde, 0	    ;Se enciende la bandera verde del semaforo 1
    bsf	    verde_t, 0	    ;Se enciende la bandera que indica que está en verde
    bsf	    PORTD, 2	    ;Se enciende el led de verde del semaforo y se
    bcf	    PORTD, 0	    ;apagan los otros leds
    bcf	    PORTD, 1	    ;
    return  
    
amarillo1:
    btfsc   amarillo, 0	    ;Se revisa si está encendida la bandera amar. del
    return		    ;semaforo 1
    movlw   3		    ;Si no es así, se mueve el valor 3 al contador
    addwf   cont, 1	    ;
    bsf	    amarillo, 0	    ;Se enciende la bandera de amarillo del semaf. 1
    bsf	    PORTD, 1	    ;Se enciende el led amarillo del semaforo y se 
    bcf	    PORTD, 0	    ;apagan los demas
    bcf	    PORTD, 2	    ;
    return
    
rojo1:
    btfsc   rojo, 0	    ;Se revisa si está encendida la bandera rojo del 
    return		    ;semaforo 1
    movf    temp1, 0	    ;Si no es así, se mueve el valor del temporizador 
    addwf   cont, 1	    ;del semaforo 2 al contador
    movf    temp2, 0	    ;Y se agrega el valor del temporizador del semaforo
    addwf   cont, 1	    ;3 al contador
    movlw   6		    ;Además que se agregan los 6s de amarillo
    addwf   cont, 1	    ;
    bsf	    rojo, 0	    ;Se enciende la bandera rojo del semaforo 1
    bsf	    PORTD, 0	    ;Se enciende el led rojo y se apagan las demas
    bcf	    PORTD, 1	    ;
    bcf	    PORTD, 2	    ;
    return
    
rojo2:
    btfsc   rojo, 1	    ;Se revisa la bandera rojo del semaforo 2
    return		    ;
    btfsc   prim_vez, 0	    ;Si no está encendida, se verifica si es la primera
    goto    segundavez	    ;vez que el semaforo 2 está en rojo
    primeravez:
    movf    temp, 0	    ;Si es la primera vez solo se mueve el valor del
    movwf   cont2	    ;temporizador del semaforo 1 al contador 2 y se 
    movlw   3		    ;agregan los 3 segundos en amarillo
    addwf   cont2, 1	    ;
    bsf	    rojo, 1	    ;Se enciende la bander de rojo del semaforo 2
    bsf	    prim_vez, 0	    ;Se enciende la bandera de primera vez
    goto    leds	    ;Se encienden los respectivos leds
    segundavez:
    bsf	    rojo, 1	    ;Si es la segunda vez que el semaforo 2 está en rojo
    movf    temp, 0	    ;Se agrega el valor del temporizador del semaforo 1
    movwf   cont2	    ;y el semaforo 3 y se agregan los 6 segundos de 
    movf    temp2, 0	    ;amarillo
    addwf   cont2, 1	    ;
    movlw   6		    ;
    addwf   cont2	    ;
    leds:
    bsf	    PORTD, 3	    ;
    bcf	    PORTD, 4	    ;
    bcf	    PORTD, 5	    ;
    return
    
verde2:
    btfsc   verde, 1	    ;Se revisa si el samaforo 2 estuvo en verde
    return		    ;Si no es así
    movf    temp1, 0	    ;Se mueve el valor del temporizador del semaforo 2
    addwf   cont2, 1	    ;al contador 2
    bsf	    verde, 1	    ;Se enciende la bandera del semaforo 2 en verde
    bsf	    verde_t, 1	    ;Se enciende la bandera que indica que está en verde
    bsf	    PORTD, 5	    ;Se enciende el led verde del semaforo 2
    bcf	    PORTD, 3	    ;
    bcf	    PORTD, 4	    ;
    return
    
amarillo2:
    btfsc   amarillo, 1	    ;Se revisa si el samaforo 2 estuvo en verde
    return		    ;Si no es así
    movlw   3		    ;Se mueve el valor del 3 del semaforo 2 al contador2 
    addwf   cont2, 1	    ;
    bsf	    amarillo, 1	    ;Se enciende la bandera del semaforo 2 en amraillo
    bsf	    PORTD, 4	    ;Se enciende el led amarillo del semaforo 2
    bcf	    PORTD, 3	    ;
    bcf	    PORTD, 5	    ;
    return
 
rojo3:
    btfsc   rojo, 2	    ;Se revisa si el semaforo 3 estuvo en rojo
    return		    ;
    clrf    cont3	    ;Si noes así, se limpia el valor de contador 3
    movf    temp, 0	    ;Y se mueve el valor del temporizador del semaforo 1
    addwf   cont3, 1	    ;y 2 al conatdor 3, además de los 6 segundos de 
    movf    temp1, 0	    ;amarillo
    addwf   cont3, 1	    ;
    movlw   6		    ;
    addwf   cont3, 1	    ;
    bsf	    rojo, 2	    ;Se enciende la bandera de rojo del semaforo 3
    bsf	    PORTD, 6	    ;Se enciende el led de rojo
    bcf	    PORTD, 7	    ;
    bcf	    PORTB, 7	    ;
    return
    
amarillo3:
    btfsc   amarillo, 2	    ;Se revisa si el semaforo 3 estuvo en amarillo
    return		    ;
    movlw   3		    ;Si no es así, se agrega el valor de 3 al contador 3
    addwf   cont3, 1	    ;
    bsf	    amarillo, 2	    ;Se enciende la bandera de amarillo del sem. 3
    bsf	    PORTD, 7	    ;Se enciende el led en amarillo
    bcf	    PORTD, 6	    ;
    bcf	    PORTB, 7	    ;
    return
   
verde3:
    btfsc   verde, 2	    ;Se revisa si el semaforo 3 estuvo en verde
    return		    ;
    movf    temp2, 0	    ;Si no es así, se agrega el valor del temporizador
    addwf   cont3, 1	    ;del semaforo 3 al contador 3
    bsf	    verde, 2	    ;
    bsf	    verde_t, 2	    ;Se enciende la bandera verde del semaforo 3
    bsf	    PORTB, 7	    ;Se enciende el led verde del semaforo 3
    bcf	    PORTD, 6	    ;
    bcf	    PORTD, 7	    ;
    return
    
reinicio1:
    bcf	    verde, 0	    ;Se limpia la bandera de verde, amarillo y rojo
    bcf	    amarillo, 0	    ;del semaforo 1
    bcf	    rojo, 0	    ;
    return
   
reinicio2:
    bcf	    verde, 1	    ;Se limpia la bandera de verde, amarillo y rojo
    bcf	    amarillo, 1	    ;del semaforo 2
    bcf	    rojo, 1	    ;
    return
    
reinicio3:
    bcf	    verde, 2	    ;Se limpia la bandera de verde, amarillo y rojo
    bcf	    amarillo, 2	    ;del semaforo 3
    bcf	    rojo, 2	    ;
    return
    
estado3:
    movf    var3, 0	    ;Se mueve el valor de la variable 3 a vd
    movwf   vd		    ;
    bsf	    PORTE, 2	    ;Se enciende el led rojo para indicar que se está
    bcf	    PORTE, 0	    ;modificando el semaforo 3
    bcf	    PORTE, 1	    ;
    return
    
estado2:
    movf    var2, 0	    ;Se mueve el valor de la variable 2 a vd
    movwf   vd		    ;
    bsf	    PORTE, 1	    ;Se enciende el led amar. para indicar que se está
    bcf	    PORTE, 2	    ;modificando el semaforo 2
    bcf	    PORTE, 0	    ;
    return
    
estado1:
    movf    var, 0	    ;Se mueve el valor de la variable 2 a vd
    movwf   vd		    ;
    bsf	    PORTE, 0	    ;Se enciende el led verde para indicar que se está
    bcf	    PORTE, 2	    ;modificando el semaforo 1
    bcf	    PORTE, 1	    ;
    return
    
estado0:
    bcf	    PORTE, 0	    ;Los leds están apagados para indicar que no se 
    bcf	    PORTE, 2	    ;encuentra en modificación los semaforos
    bcf	    PORTE, 1	    ;
    return
    
preparar_display:
    prep_display    vard, display_var	    ;Se utiliza un macro para mover el 
    prep_display    varu, display_var+1	    ;valor de las unidades y decenas
    prep_display    vard1, display_var+2    ;a cada una de las variables del
    prep_display    varu1, display_var+3    ;display para mostrarse en los 
    prep_display    vard2, display_var+4    ;7 segmentos
    prep_display    varu2, display_var+5    ;
    prep_display    vard3, display_var+6    ;
    prep_display    varu3, display_var+7    ;
    return
    
reinicio:
    movlw   01000000B	    ;Se muestra una línea en cada uno de los display
    movwf   display_var+2    ;para indicar un reinicio
    movwf   display_var+3    ;
    movwf   display_var+4    ;
    movwf   display_var+5    ;
    movwf   display_var+6    ;
    movwf   display_var+7    ;
    bsf	    PORTD,0	    ;Se ponen todos los semaforos en rojo
    bsf	    PORTD, 3	    ;
    bsf	    PORTD, 6	    ;
    btfsc   rein, 1	    ;Si la segunda bandera de reinicio no ha sido apag.
    goto    $-11	    ;Se muestra lo anterior
    bcf	    rein, 0	    ;De lo contrario, se limpia la bandera de reinicio
    bcf	    prim_vez, 0	    ;Se limpia la bandera de primera vez del semaforo 2
    call    verde1	    ;Se pone en verde el semaforo 1
    call    rojo2	    ;En rojo el semaforo 2
    call    rojo3	    ;Y en rojo el semaforo 3
    goto    loop	    ;Se ejecuta el principio del loop
    
verde_tit1:
    btfss   verde_t, 0	    ;Se revisa si el bit cero de verde_t está en 1
    return		    ;Si no, retorna
    movlw   3		    ;
    subwf   cont,0	    ;
    btfsc   ZERO   	    ;Si la variable cont es igual a 3
    bsf	    tit_verd, 0	    ;Se pone en 1 el bit 0 de tit_verd
    movlw   1		    ;
    subwf   cont, 0	    ;
    btfsc   ZERO	    ;Si la variable cont es igual a 1
    bcf     tit_verd, 0	    ;Se pone en 0 el bit 0 de tit_verd
    btfsc   ZERO	    ;
    bcf	    verde_t, 0	    ;Y se pone en 0 el bit 0 de verde_t
    return
    
verde_tit2:
    btfss   verde_t, 1	    ;Se revisa si el bit 1 de verde_t está en 1
    return		    ;Si no, retorna
    movlw   3		    ;
    subwf   cont2,0	    ;
    btfsc   ZERO	    ;Si la variable cont2 es igual a 3
    bsf	    tit_verd, 1	    ;Se pone en 1 el bit 1 de tit_verd
    movlw   1		    ;
    subwf   cont2, 0	    ;Si la variable cont2 es igual a 1
    btfsc   ZERO	    ;
    bcf	    tit_verd, 1	    ;Se pone en 0 el bit 1 de tit_verd
    btfsc   ZERO	    ;
    bcf	    verde_t, 1	    ;Y se pone en 0 el bit 1 de verde_t
    return
    
verde_tit3:
    btfss   verde_t, 2	    ;Se revisa si el bit 2 de verde_t está en 1
    return		    ;Si no, retorna
    movlw   3		    ;
    subwf   cont3,0	    ;
    btfsc   ZERO	    ;Si la variable cont3 es igual a 3
    bsf	    tit_verd, 2	    ;Se pone en 1 el bit 2 de tit_verd
    movlw   1		    ;
    subwf   cont3, 0	    ;Si la variable cont3 es igual a 1
    btfsc   ZERO	    ;
    bcf	    tit_verd, 2	    ;Se pone en 0 el bit 2 de tit_verd
    btfsc   ZERO	    ;
    bcf	    verde_t, 2	    ;Y se pone en 0 el bit 2 de verde_t
    return
    
overf:
    movlw   5		    ;Si el valor de estado es igual a 5, este se pone
    subwf   estado, 0	    ;en 0
    btfsc   CARRY	    ;
    clrf    estado	    ; overflow de los estados
    return
    