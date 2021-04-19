/* 
 * File:   main.c
 * Author: Oscar Fuentes
 *
 * Archivo template para generación de proyectos
 * 
 * Created on 13 de abril de 2021, 10:48 AM
 */

//------------------------------------------------------------------------------
//                      Implementación de librerias                             
//------------------------------------------------------------------------------

#include <stdio.h>
#include <stdlib.h>
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

//------------------------------------------------------------------------------
//                      Variables                             
//------------------------------------------------------------------------------

unsigned int display1, display2, display3; //Se declaran las variables de disp
unsigned int d = 0;                        //Se declara la variable de multipl.
                                           //del display
//uint8_t variable2;

//------------------------------------------------------------------------------
//                      Prototipo de funciones                             
//------------------------------------------------------------------------------
void setup(void);               //Se declaran todas las funciones a usar
int centena(int a);
int decena(int a);
int unidad(int a);
int valor(int a);

void __interrupt() Interrupciones(void){
    if(INTCONbits.RBIF){            //Si se enciende la bandera del puerto B
        if (PORTBbits.RB0 == 0)     //Si se presiona el primer boton que incre.
            PORTD++;
        if (PORTBbits.RB1 == 0)     //Si se presiona el 2do boton que decr.
            PORTD--;
        INTCONbits.RBIF = 0;        //Se limpia la bandera del puerto B
    }
    if(INTCONbits.T0IF){            //Si se enciende la bandera del tmr0
        TMR0 = 178;                 //Se resetea
        INTCONbits.T0IF = 0;
        PORTE = 0x00;               //Se limpia el puerto de multiplexado
        
        if (d == 0){                //Si d es igual a 0, se muestra las centenas
            PORTC = display1;
            PORTE = 0x01;
            d = 1;                  //D cambia para mostrar el sig. displ.
        }
        else if (d == 1){           //Se muestra el otro display con la decena
            PORTC = display2;
            PORTE = 0x02;
            d = 2;
        }
        else if (d == 2){           //Se muestra el otro display con la unidad
            PORTC = display3;
            PORTE = 0x04;
            d = 0;
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
        int cent, dec, un;      //Se declaran las variables que se usara 
        cent = centena(PORTD);  //Se coloca llama el valor de la centena
        dec = decena(PORTD);    //Se llama el valor de la decena
        un = unidad(PORTD);     //Se llama el valor de la unidad
        
        display1 = valor(cent); //El valor de display 1 será el de centena
        display2 = valor(dec);  //El valor de display 2 será el de decena
        display3 = valor(un);   //El valor de display 3 será de unidad
    }
    
}

//------------------------------------------------------------------------------
//                      Configuración                            
//------------------------------------------------------------------------------

void setup(void){
    //Configuración de puertos
    ANSEL = 0x00;           //Todas las entradas y salidas son digitales
    ANSELH = 0x00;
    
    TRISA = 0x00;           //El puerto A, C, D y E son salida, mientras que en
    TRISB = 0xFF;           //B son entradas
    TRISC = 0x00;
    TRISD = 0x00;
    TRISE = 0x00;
    
    PORTA = 0x00;           //Se limpian todos los puertos que son salida
    PORTC = 0x00;
    PORTD = 0x00;
    PORTE = 0x00;
    
    //Configuración del oscilador 
    OSCCONbits.IRCF2 = 1;       //Se configura el oscilador a 1Mhz
    OSCCONbits.IRCF1 = 1;
    OSCCONbits.IRCF0 = 0;
    OSCCONbits.SCS = 1;         //Se utiliza el oscilador interno
    
    //Configuración del timer0
    OPTION_REGbits.T0CS = 0;   //Se utiliza el oscilador int. para el tmr0
    OPTION_REGbits.PSA = 0;    
    OPTION_REGbits.PS2 = 1;
    OPTION_REGbits.PS1 = 0;
    OPTION_REGbits.PS0 = 1;    //Prescaler de 64
    TMR0 =  178;               //El valor del TMR0 es igual a 178
    
    //Configuración de interrupciones
    INTCONbits.T0IF = 0;       //Se habilita las interrupciones del tmr0 y del
    INTCONbits.T0IE = 1;       //puerto B
    INTCONbits.RBIE = 1;
    INTCONbits.RBIF = 0;
    INTCONbits.GIE = 1;
    
    //Coniguración del puerto B para pull-up
    OPTION_REGbits.nRBPU = 0;   //Se habilitan los pull up de los puertos B
    WPUBbits.WPUB0 = 1;         //Se habilita el pull up de los dos botones
    WPUBbits.WPUB1 = 1;
    
    //Configuración interrupt on change
    IOCBbits.IOCB0 = 1;         //Se habilita la interrupcion de los botones
    IOCBbits.IOCB1 = 1;
    
}

//------------------------------------------------------------------------------
//                      Funciones                           
//------------------------------------------------------------------------------

int centena(int a){
    int b = a/100;          //Se divide el valor del puerto en 100
    return b;               //El valor de la división se regresa
}

int decena(int a){
    int cent = a/100;       //Se divide entre 100 el valor del puerto
    cent = cent *100;       //Se resta el valor de las centenas
    a = a - cent;           
    int dec = a/10;         //Se divide el valor del puerto entre 10
    return dec;             //Se regresa el valor de las decenas
}

int unidad(int a){
    int cent = a/100;       //Al valor del puerto se le resta el valor de las
    cent = cent * 100;      //centenas y de las decenas
    a = a-cent;
    int dec = a/10;
    dec = dec * 10;
    int un = a-dec;
    return un;              //El valor de las unidades se regresa
}

int valor(int a){           
    int display;            //Se declara la valarable a retornar
    switch(a){
        case 0:
            display = 0x3F;  //Se regresa el valor de 0 para mostrar en el disp.
            break;
        case 1:
            display = 0x06;  //Se regresa el valor de 1 para mostrar en el disp.
            break;
        case 2:
            display = 0x5B;  //Se regresa el valor de 2 para mostrar en el disp.
            break;
        case 3:
            display = 0x4F;  //Se regresa el valor de 3 para mostrar en el disp.
            break;
        case 4:
            display = 0x66;  //Se regresa el valor de 4 para mostrar en el disp.
            break;
        case 5:
            display = 0x6D;  //Se regresa el valor de 5 para mostrar en el disp.
            break;
        case 6:
            display = 0x7D;  //Se regresa el valor de 6 para mostrar en el disp.
            break;
        case 7:
            display = 0x07;  //Se regresa el valor de 7 para mostrar en el disp.
            break;
        case 8:
            display = 0x7F;  //Se regresa el valor de 8 para mostrar en el disp.
            break;
        case 9:
            display = 0x67;  //Se regresa el valor de 9 para mostrar en el disp.
            break;
    }
    return display;     //Se retorna el valor del display
}