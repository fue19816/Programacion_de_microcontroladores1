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

//unsigned int display1, display2, display3; //Se declaran las variables de disp
//unsigned int d = 0;                       //Se declara la variable de multipl.
unsigned int lec;                                           //del display


//------------------------------------------------------------------------------
//                      Prototipo de funciones                             
//------------------------------------------------------------------------------
void setup(void);               //Se declaran todas las funciones a usar

void __interrupt() Interrupciones(void){
    if (PIR1bits.ADIF == 1){
        PIR1bits.ADIF = 0;
        if (ADCON0bits.CHS == 0){               //Se verifica el canal
            CCPR1L = (ADRESH>>1) + 128;        //El registro del PWM empieza 
                                               //desde 128 a 256

            CCP1CONbits.DC1B1 = ADRESH & 0b01; //Se colocan los bits menos sign.
            CCP1CONbits.DC1B0 = ADRESL>>7;      
            ADCON0bits.CHS = 1;                //Se cambia de canal
        }
        else if(ADCON0bits.CHS == 1){
            CCPR2L = (ADRESH>>1) + 128;     //El registro del PWM empieza 
                                            //desde 128 a 256
            
            CCP2CONbits.DC2B1 = ADRESH & 0b01;  //Se colocan los bits menos sig.
            CCP2CONbits.DC2B0 = ADRESL>>7; 
            ADCON0bits.CHS = 0;     //Se cambia de canal
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
        if (ADCON0bits.GO == 0){
            __delay_us(50);     //Se realiza un delay por cada cambio de canal
            ADCON0bits.GO = 1;  //Se vuelve a realizar la lectura
        }
    }
    
}

//------------------------------------------------------------------------------
//                      Configuración                            
//------------------------------------------------------------------------------

void setup(void){
    //Configuración de puertos
    ANSEL = 0x03;           //Se configura las entradas analogicas
    ANSELH = 0x00;
    
    TRISA = 0x03;           //El puerto B, C, D y E son salida, mientras que en
    TRISB = 0x00;           //B son entradas
    TRISC = 0x00;
    TRISD = 0x00;
    TRISE = 0x00;

    PORTC = 0x00;           //Se limpian todos los puertos que son salida
    PORTD = 0x00;
    PORTE = 0x00;
    
    //Configuración del oscilador 
    OSCCONbits.IRCF2 = 1;       //Se configura el oscilador a 8Mhz
    OSCCONbits.IRCF1 = 1;
    OSCCONbits.IRCF0 = 1;
    OSCCONbits.SCS = 1;         //Se utiliza el oscilador interno
    
    //Configuración de interrupciones
    INTCONbits.PEIE = 1;
    PIE1bits.ADIE = 1;
    PIR1bits.ADIF = 0;
    INTCONbits.GIE = 1;
    
    //-------------------Configuración del PWM----------------------------------
    TRISCbits.TRISC2 = 1;            //Se habilitan los pines encargados de
    TRISCbits.TRISC1 = 1;            //de los servos
    PR2 = 249;                      //Se coloca el registro de PR2 para 2ms
    
    //CCP1
    CCP1CONbits.P1M = 0;            //Se utiliza una salida individual
    CCP1CONbits.CCP1M = 0b00001100; //Se utiliza la función de PWM
    CCPR1L = 0x0F;                  //El registro empieza en 15
    CCP1CONbits.DC1B = 0;           //Los bits menos sign se colocan en 0
    
    //CCP2
    CCP2CONbits.CCP2M = 0b00001111; //Se utiliza la función PWM
    CCPR2L = 0x0F;                  
    CCP2CONbits.DC2B0 = 0;          //Se ponen en 0 los bits menos sign.
    CCP2CONbits.DC2B1 = 0;
    
    PIR1bits.TMR2IF = 0;            //Se habilita la interr. del tmr2
    T2CONbits.T2CKPS = 0b11;        //El prescaler es de 16
    T2CONbits.TMR2ON = 1;           //Se enciende el TMR2
    
    while (!PIR1bits.TMR2IF);       //Cuando se cumple un ciclo del TMR2
    PIR1bits.TMR2IF = 0;            //Se limpia la bandera
    TRISCbits.TRISC2 = 0;           //Los pines del puerto C se colocan en 0
    TRISCbits.TRISC1 = 0;
    
    //--------------------------------------------------------------------------
    //Configuración del ADC
    ADCON0bits.ADON = 1;        //Funcione el ADC
    ADCON1bits.ADFM = 0;        //Justificado a la izquierda
    ADCON0bits.GO   = 1;        // Lectura del potenciometro
    ADCON1bits.VCFG0 = 0;       //Voltajes de referencia 
    ADCON1bits.VCFG1 = 0;       //
    ADCON0bits.CHS = 0;         // Pin AN0 para leer
    ADCON0bits.ADCS = 1;        // Clock selection
    __delay_us(50);
}
