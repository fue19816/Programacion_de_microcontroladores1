/* 
 * File:   main.c
 * Author: Oscar Fuentes
 *
 * Archivo template para generación de proyectos
 * 
 * Created on 04 de mayo de 2021, 10:32 AM
 */

//------------------------------------------------------------------------------
//                      Implementación de librerias                             
//------------------------------------------------------------------------------

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <xc.h>

//------------------------------------------------------------------------------
//                     Configuración del PIC                            
//------------------------------------------------------------------------------

// CONFIG1
#pragma config FOSC = INTRC_CLKOUT// Oscillator Selection bits (INTOSC oscillator: CLKOUT function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
#pragma config WDTE = OFF       // Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
#pragma config PWRTE = OFF      // Power-up Timer Enable bit (PWRT disabled)
#pragma config MCLRE = OFF      // RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
#pragma config CP = OFF         // Code Protection bit (Program memory code protection is disabled)
#pragma config CPD = OFF        // Data Code Protection bit (Data memory code protection is disabled)
#pragma config BOREN = OFF      // Brown Out Reset Selection bits (BOR disabled)
#pragma config IESO = OFF       // Internal External Switchover bit (Internal/External Switchover mode is disabled)
#pragma config FCMEN = OFF      // Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
#pragma config LVP = ON         // Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

// CONFIG2
#pragma config BOR4V = BOR40V   // Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
#pragma config WRT = OFF        // Flash Program Memory Self Write Enable bits (Write protection off)
#define _XTAL_FREQ 8000000
//------------------------------------------------------------------------------
//                      Variables                             
//------------------------------------------------------------------------------

int ban = 1;
uint8_t dato = 0;
uint8_t d2;
uint8_t d3;
uint8_t b = 0;
char txt [] = "Que accion desea ejecutar??";
char txt1 [] = "[1] Desplegar cadena de carecteress";
char txt2 [] = "[2] Cambiar PORTAA";
char txt3 [] = "[3] Cambiar PORTB";
char cad [] = "abcdefgh";
char puertoa [] = "Presione una tecla para el puerto A";
char puertob [] = "Presione una tecla para el puerto B";

//------------------------------------------------------------------------------
//                      Prototipo de funciones                             
//------------------------------------------------------------------------------
void setup(void);               //Se declaran todas las funciones a usar
void menu(void);
void envio_caract(char st[]);
void envio_char(char dato);

void __interrupt() Interrupciones(void){
    if (PIR1bits.RCIF){
        dato = RCREG;       //Se guarda el dato recibido en la variable dato
        if (b == 1){
            d2 = 0;         //Se colocan banderas para salir del ciclo while
            d3 = 0;         //en cada uno de las configuraciones de los puertos
        }
    }
      
}

//------------------------------------------------------------------------------
//                      Ciclo principal                            
//------------------------------------------------------------------------------
void main(void) {
    setup();    //Se llama a las configuraciones del pic
    //--------------------------------------------------------------------------
    //                      Loop principal                                      
    //--------------------------------------------------------------------------
    while(1){
        __delay_ms(500);
        menu();
    } 
 }

//------------------------------------------------------------------------------
//                      Configuración                            
//------------------------------------------------------------------------------

void setup(void){
    //Configuración de puertos
    ANSEL = 0x00;           //Se configura las entradas analogicas
    ANSELH = 0x00;
    
    TRISA = 0x00;           //El puerto A es salida
    TRISB = 0x00;
    
    PORTA = 0x00;
    PORTB = 0x00;
    PORTC = 0x00;           //Se limpian todos los puertos que son salida
    PORTD = 0x00;
    PORTE = 0x00;
    
    //Configuración del oscilador 
    OSCCONbits.IRCF2 = 1;       //Se configura el oscilador a 8Mhz
    OSCCONbits.IRCF1 = 1;
    OSCCONbits.IRCF0 = 1;
    OSCCONbits.SCS = 1;         //Se utiliza el oscilador interno
    
    //Configuración de TX y RX
    TXSTAbits.SYNC = 0;         //La configuración es asíncrona
    TXSTAbits.BRGH = 0;         //Según configuración a 9600 del baud rate
    
    BAUDCTLbits.BRG16 = 1;
    
    SPBRG = 51;
    SPBRGH = 0;
    
    RCSTAbits.SPEN =1;          
    RCSTAbits.RX9 = 0;
    RCSTAbits.CREN = 1;         //Habilitación de recibimiento de datos
    
    TXSTAbits.TXEN = 1;         //Habilitación de transmisión de datos
    
    //Configuración de interrupciones
    INTCONbits.PEIE = 1;        
    PIE1bits.RCIE = 1;          //Interrupción al recibir datos
    PIR1bits.RCIF = 0;
    INTCONbits.GIE = 1;
}

void menu(void){
    if (ban == 1){              //Se revisa una bandera para el menu
     envio_caract(txt);         //Se despliega el menu
     TXREG = '\r';
     envio_caract(txt1);
     TXREG = '\r';
     envio_caract(txt2);
     TXREG = '\r';
     envio_caract(txt3);
     ban = 0;                   //Se pone en 0 la band. para no mostrar el menu
     b = 0;                     //Se pone en 0 la bandera de datos en porta y b
    }
    
    if (dato == '1'){
        dato1();                //Se llama a la subrutina para mostrar caracter.
     }
    
    else if (dato == '2'){
        d2 = 1;                 //Se enciende la bandera para entre al ciclo
        TXREG = '\f';           //Se limpia la terminal
        __delay_ms(50);         //Se realiza un delay para mostrar el mensaje
        envio_caract(puertoa);  //Se muestra el mensaje
        
        while(d2 == 1){
            PORTA = RCREG;      //El valor del dato se mueve al PORTA
            b = 1;              //Se enciende la bandera para la proxima vez no
        }                       //ocurra el ciclo
        dato = 0;               //Para evitar saltos del menu se coloca en 0 dat
        ban = 1;                //Se habilita el menu
        TXREG = '\f';           //Se limpia nuevamente la terminal
    }
    
    else if (dato == '3'){
       //Funcionamiento igual al dato == 2
        d3 = 1;
        TXREG = '\f';
        __delay_ms(50);
        envio_caract(puertob);
        
        while(d3 == 1){
            PORTB = RCREG;
            b = 1;
        }
        dato = 0;
        ban = 1;
        TXREG = '\f';
    }
}

void envio_caract(char st[]){
    int i = 0;              //Se declara una variable que recorrera la cadena
    while (st[i] != 0){     //Mientras st no sea igual a 0
        envio_char(st[i]);  //Se enviara el caracter por caracter
        i++;                //Se aumenta en 1 el caracter a mostrar en la cadena
    }
}

void envio_char(char dato){
    while(!TXIF);           //Mientras la bandera de transmisión sea 0
    TXREG = dato;           //Se envía el caracter
}

void dato1 (void){
    TXREG = '\f';           //Se limpia la consola
    __delay_ms(50);         
    envio_caract(cad);      //Se envían los carácteres
    dato = 0;               //Dato se pone en 0 para evitar saltos del menu
    ban = 1;                //Se habilita el menu
    __delay_ms(500);
    TXREG = '\f';           //Se vuelve a limpiar la consola
}