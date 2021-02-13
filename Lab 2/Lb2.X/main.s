; Archivo:     main.S
; Dispositivo: PIC16F8870
; Autor:       Oscar Fuentes
; Compilador:  pic-as (v2.30), MPLABX V5.45
;
; Programa:    contador
; Hardware:    LEDs en el puerto C
;
; Creado: 09 feb, 2021
; última modificación: 09 feb, 2021

; Assembly source line config statements

PROCESSOR 16F887
#include <xc.inc>

; CONFIG1
  CONFIG  FOSC = XT		; Oscillator Selection bits 
  CONFIG  WDTE = OFF		; Watchdog Timer Enable bit 
  CONFIG  PWRTE = ON		; Power-up Timer Enable bit 
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit 
  CONFIG  CP = OFF              ; Code Protection bit 
  CONFIG  CPD = OFF             ; Data Code Protection bit 
 
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits 
  CONFIG  IESO = OFF            ; Internal External Switchover bit 
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit 
  CONFIG  LVP = ON              ; Low Voltage Programming Enable bit 

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit 
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits 
  
 PSECT resVect, class=CODE, abs, delta=2
 ;-----------vector reset-------------------------------------------------------
 ORG 00h		;posición 0000h para el reset
 resetVec:
    PAGESEL main
    goto main
    
 PSECT code, delta=2, abs
 ORG 100h		;posición para el código
 
 ;---------------------configuración--------------------------------------------
 main:
    BANKSEL ANSEL	;
    CLRF    ANSEL	;
    clrf    ANSELH
    
    BANKSEL TRISA	;
    MOVLW   11111111B	; Todos los pines de A serán de entrada
    MOVWF   TRISA	;
    MOVLW   11110000B	; Los primeros 4 pines del puerto B serán de salida
    MOVWF   TRISB	;
    MOVLW   11110000B	; Los primeros 4 pines del puerto C serán de salida
    MOVWF   TRISC	;
    MOVLW   11100000B	; Los primeros 5 pines del puerto D serán de salida
    MOVWF   TRISD	;
    
    BANKSEL PORTA	;
    CLRF    PORTB	;
    CLRF    PORTC	;
    CLRF    PORTD	;

;----------------------loop principal-------------------------------------------
loop:
    BTFSC PORTA, 0	;Revisa el pin 0 del puerto A
    call inc_portb	; Si el botón es presionado se incrementa el contador 1
    BTFSC PORTA, 1	;Revisa el pin 1 del puerto A
    call dec_portb	; Si el botón es presionado se decrementa el contador 1
    btfsc PORTA, 2	;Revisa el pin 2 del puerto A
    call inc_portc	; Si el botón es presionado se incrementa el contador 2
    btfsc PORTA, 3	;Revisa el pin 3 del puerto A
    call dec_portc	; Si el botón es presionado se decrementa el contador 2
    btfsc PORTA, 4	;Revisa el pin 4 del puerto A
    call sumad		; Realiza la suma entre los contadores
    goto loop		;
    
;----------------------subrutinas-----------------------------------------------
    inc_portb:
	BTFSC PORTA, 0	    ;Antirrebote
	goto $-1	    ;
	incf  PORTB, F	    ;Se incrementa el contador 1
	return
	
    dec_portb:
	BTFSC PORTA, 1	    ;Antirrebote
	goto $-1
	decf PORTB, F	    ;Se decrementa el contador 1
	return		    ;
    
    inc_portc:
	btfsc PORTA, 2	    ;Antirrebote
	goto $-1	    ;
	incf PORTC, F	    ; Se incrementa el contador 2
	return
    
    dec_portc:
	btfsc PORTA, 3	    ;Antirrebote
	goto $-1	    ;
	decf PORTC, F	    ;Se decrementa el contador 2
	return
	
    sumad:
	btfsc PORTA, 4	    ;Antirrebote
	goto $-1	    ;
	movf  PORTB, 0	    ;Se mueve el valor del puerto B a w
	addwf PORTC, 0	    ;A w se agrega el valor del puerto C
	movwf PORTD	    ;Se mueve el valor de w al puerto D
	return
