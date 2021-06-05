/* 
 * File:   main.c
 * Author: Oscar Fuentes
 *
 * Archivo template para generación de proyectos
 * 
 * Created on 3 de mayo de 2021, 21:56 PM
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

#define addressEEPROM1 0x10
#define addressEEPROM2 0x11
#define addressEEPROM3 0x12
#define addressEEPROM3l 0x13
#define addressEEPROM4 0x14
#define addressEEPROM4l 0x15
//------------------------------------------------------------------------------
//                      Variables                             
//------------------------------------------------------------------------------

uint8_t valor_pot1;
uint8_t valor_pot2;
uint8_t valor_pot3;
uint8_t valor_pot3l;
uint8_t valor_pot4;
uint8_t valor_pot4l;
int     delay_func_serv;
int     delay_per_serv;
uint8_t dato_mem1;
uint8_t dato_mem2;
uint8_t dato_mem3;
uint8_t dato_mem3l;
uint8_t dato_mem4;
uint8_t dato_mem4l;
int     RB0_old = 0;
int     band_mem = 0;

//------------------------------------------------------------------------------
//                      Prototipo de funciones                             
//------------------------------------------------------------------------------
void setup(void);               //Se declaran todas las funciones a usar
void servoRotate(void);
void servo1Rotate0(void);
void servo1Rotate90(void);
void servo1Rotate180(void);
void servo2Rotate0(void);
void servo2Rotate90(void);
void servo2Rotate180(void);
void writeToEEPROM(uint8_t data, uint8_t address);
uint8_t readFromEEPROM(uint8_t address);
void envio_caract(char st[]);
void envio_char(char dato);
uint8_t dato;

char txt [] = "Que accion desea ejecutar??";
char txt1 [] = "[1] Mover pata derecha a 0°";
char txt2 [] = "[2] Mover pata derecha a 90°";
char txt3 [] = "[3] Mover pata derecha a 180°";
char txt4 [] = "[4] Mover pata izquierda a 0°";
char txt5 [] = "[5] Mover pata izquierda a 90°";
char txt6 [] = "[6] Mover pata izquierda a 180°";
char txt7 [] = "[7] Mover pie izquierdo a 0°";
char txt8 [] = "[8] Mover pie izquierdo a 90°";
char txt9 [] = "[9] Mover pie izquierdo a 180°";
char txt10 [] = "[10] Mover pie derecho a 0°";
char txt11 [] = "[11] Mover pie derecho a 90°";
char txt12 [] = "[12] Mover pie derecho a 180°";
char txt13 [] = "Moviendo servomotor...";


void __interrupt() Interrupciones(void){
    if (PIR1bits.ADIF == 1){
        PIR1bits.ADIF = 0;
        
        if (ADCON0bits.CHS == 0){
            if (band_mem == 0){
             valor_pot1 = ADRESH;        //La variable tendrá el valor de ADRESH   
            }
            else{
                valor_pot1 = dato_mem1;
            }
             ADCON0bits.CHS = 1;
        }
        
        else if (ADCON0bits.CHS == 1){
            if (band_mem == 0){
               valor_pot2 = ADRESH;
            }
            else{
             valor_pot2 = dato_mem2;   
            }
            ADCON0bits.CHS = 2;
        }
        
        else if (ADCON0bits.CHS == 2){               //Se verifica el canal
            if (band_mem == 0){
                valor_pot3 = ADRESH;
                valor_pot3l = ADRESL;
            }
            else{
                valor_pot3 = dato_mem3; 
                valor_pot3l = dato_mem3l; 
            }
            CCPR1L = (valor_pot3>>1) + 128;        //El registro del PWM empieza 
                                               //desde 128 a 256

            CCP1CONbits.DC1B1 = valor_pot3 & 0b01; //Se colocan los bits menos sign.
            CCP1CONbits.DC1B0 = valor_pot3l>>7;      
            ADCON0bits.CHS = 3;                //Se cambia de canal
        }
        
        else if(ADCON0bits.CHS == 3){
            if (band_mem == 0){
                valor_pot4 = ADRESH;
                valor_pot4l = ADRESL;
            }
            else{
                valor_pot4 = dato_mem4; 
                valor_pot4l = dato_mem4l; 
            }
            CCPR2L = (valor_pot4>>1) + 128;     //El registro del PWM empieza 
                                            //desde 128 a 256
            
            CCP2CONbits.DC2B1 = valor_pot4 & 0b01;  //Se colocan los bits menos sig.
            CCP2CONbits.DC2B0 = valor_pot4l>>7; 
            ADCON0bits.CHS = 0;     //Se cambia de canal
        }
    }
    if (INTCONbits.RBIF == 1){
        INTCONbits.RBIF = 0;
        if (PORTBbits.RB1 == 0){
            if (band_mem == 0){
                band_mem = 1;
                PORTEbits.RE0 = 1;
                PORTEbits.RE1 = 0;
            }
            else if (band_mem == 1){
                band_mem = 0;
                PORTEbits.RE1 = 1;
                PORTEbits.RE0 = 0;
            }   
        }
    }
    
//    if (PIR1bits.RCIF){
//        dato = RCREG;
//    }
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
            __delay_us(50);
            ADCON0bits.GO = 1;
            
            if (ADCON0bits.CHS == 0){
                if (valor_pot1 <= 85){
                    servo1Rotate0();   
                }
                else if (valor_pot1 <= 170){
                    servo1Rotate90();    
                }
                else{
                    servo1Rotate180();    
                }
            }
            if (ADCON0bits.CHS == 1){
              if (valor_pot2 <= 85){
                    servo2Rotate0();   
                }
                else if (valor_pot2 <= 170){
                    servo2Rotate90();    
                }
                else{
                    servo2Rotate180();   
                }   
            }
        }
        
        dato_mem1 = readFromEEPROM(addressEEPROM1);
        dato_mem2 = readFromEEPROM(addressEEPROM2);
        dato_mem3 = readFromEEPROM(addressEEPROM3);
        dato_mem3l = readFromEEPROM(addressEEPROM3l);
        dato_mem4 = readFromEEPROM(addressEEPROM4);
        dato_mem4l = readFromEEPROM(addressEEPROM4l);
        
        PORTD = dato_mem1; 

        if (RB0 == 1 && RB0_old == 0){
            writeToEEPROM(valor_pot1, addressEEPROM1);
            writeToEEPROM(valor_pot2, addressEEPROM2);
            writeToEEPROM(valor_pot3, addressEEPROM3);
            writeToEEPROM(valor_pot3l, addressEEPROM3l);
            writeToEEPROM(valor_pot4, addressEEPROM4);
            writeToEEPROM(valor_pot4l, addressEEPROM4l);
        }
        
        RB0_old = RB0;
        
//        void menu(void){
//            envio_caract(txt);         //Se despliega el menu
//            TXREG = '\r';
//            envio_caract(txt1);
//            TXREG = '\r';
//            envio_caract(txt2);
//            TXREG = '\r';
//            envio_caract(txt3);
//            TXREG = '\r';
//            envio_caract(txt4);
//            TXREG = '\r';
//            envio_caract(txt5);
//            TXREG = '\r';
//            envio_caract(txt6);
//            TXREG = '\r';
//            envio_caract(txt7);
//            TXREG = '\r';
//            envio_caract(txt8);
//            TXREG = '\r';
//            envio_caract(txt9);
//            TXREG = '\r';
//            envio_caract(txt10);
//            TXREG = '\r';
//            envio_caract(txt11);
//            TXREG = '\r';
//            envio_caract(txt12);
//            
//            switch (dato){
//                case 1:
//                    servo1Rotate0();
//                    TXREG = '\f';           //Se limpia la terminal
//                    __delay_ms(50);
//                    envio_caract(txt13);
//                    TXREG = '\f';
//                    __delay_ms(50);
//                    break;
//                
//                case 2:
//                    servo1Rotate90();
//                    TXREG = '\f';           //Se limpia la terminal
//                    __delay_ms(50);
//                    envio_caract(txt13);
//                    TXREG = '\f';
//                    __delay_ms(50);
//                    break;
//                
//                case 3:
//                    servo1Rotate180();
//                    TXREG = '\f';           //Se limpia la terminal
//                    __delay_ms(50);
//                    envio_caract(txt13);
//                    TXREG = '\f';
//                    __delay_ms(50);
//                    break;
//                
//                case 4:
//                    servo2Rotate0();
//                    TXREG = '\f';           //Se limpia la terminal
//                    __delay_ms(50);
//                    envio_caract(txt13);
//                    TXREG = '\f';
//                    __delay_ms(50);
//                    break;
//                
//                case 5:
//                    servo2Rotate90();
//                    TXREG = '\f';           //Se limpia la terminal
//                    __delay_ms(50);
//                    envio_caract(txt13);
//                    TXREG = '\f';
//                    __delay_ms(50);
//                    break;
//                
//                case 6:
//                    servo2Rotate180();
//                    TXREG = '\f';           //Se limpia la terminal
//                    __delay_ms(50);
//                    envio_caract(txt13);
//                    TXREG = '\f';
//                    __delay_ms(50);
//                    break;
//                    
//                case 7:
//                    servo1Rotate0();
//                    TXREG = '\f';           //Se limpia la terminal
//                    __delay_ms(50);
//                    envio_caract(txt13);
//                    TXREG = '\f';
//                    __delay_ms(50);
//                    break;
//                
//                case 8:
//                    servo1Rotate90();
//                    TXREG = '\f';           //Se limpia la terminal
//                    __delay_ms(50);
//                    envio_caract(txt13);
//                    TXREG = '\f';
//                    __delay_ms(50);
//                    break;
//                    
//                case 9:
//                    servo1Rotate180();
//                    TXREG = '\f';           //Se limpia la terminal
//                    __delay_ms(50);
//                    envio_caract(txt13);
//                    TXREG = '\f';
//                    __delay_ms(50);
//                    break;
//                    
//                case 10:
//                    servo1Rotate0();
//                    TXREG = '\f';           //Se limpia la terminal
//                    __delay_ms(50);
//                    envio_caract(txt13);
//                    TXREG = '\f';
//                    __delay_ms(50);
//                    break;
//                    
//                case 11:
//                    servo1Rotate90();
//                    TXREG = '\f';           //Se limpia la terminal
//                    __delay_ms(50);
//                    envio_caract(txt13);
//                    TXREG = '\f';
//                    __delay_ms(50);
//                    break;
//                    
//                case 12:
//                    servo1Rotate180();
//                    TXREG = '\f';           //Se limpia la terminal
//                    __delay_ms(50);
//                    envio_caract(txt13);
//                    TXREG = '\f';
//                    __delay_ms(50);
//                    break;
//            }
//        }
    }
    
}



void setup(void){
    //Configuración de puertos
    ANSEL = 0x0F;           //Se configura las entradas analogicas
    ANSELH = 0x00;
    
    TRISA = 0x0F;           //El puerto B, C, D y E son salida, mientras que en
    TRISB = 0x03;           //B son entradas
    TRISC = 0x00;
    TRISD = 0x00;
    TRISE = 0x00;

    PORTB = 0x00;
    PORTC = 0x00;           //Se limpian todos los puertos que son salida
    PORTD = 0x00;
    PORTE = 0x00;
    
    //Configuración Pull-UP
    OPTION_REGbits.nRBPU = 0;
    WPUB = 0b011;
    
//    //Puerto B
    IOCBbits.IOCB0 = 1;
    IOCBbits.IOCB1 = 1;
    
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
    INTCONbits.RBIE = 1;
    INTCONbits.RBIF = 0;
    PIE1bits.RCIE = 1;          //Interrupción al recibir datos
    PIR1bits.RCIF = 0;
    
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
    
//    //Configuración de TX y RX
//    TXSTAbits.SYNC = 0;         //La configuración es asíncrona
//    TXSTAbits.BRGH = 0;         //Según configuración a 9600 del baud rate
//    
//    BAUDCTLbits.BRG16 = 1;
//    
//    SPBRG = 51;
//    SPBRGH = 0;
//    
//    RCSTAbits.SPEN =1;          
//    RCSTAbits.RX9 = 0;
//    RCSTAbits.CREN = 1;         //Habilitación de recibimiento de datos
//    
//    TXSTAbits.TXEN = 1;         //Habilitación de transmisión de datos
//    
    
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

void servo1Rotate0(void) //0 Degree
{
    unsigned int i;
    for(i=0;i<10;i++)
    {
       PORTCbits.RC0 = 1;
       __delay_us(800);
       PORTCbits.RC0 = 0;
       __delay_us(19200);
    }
}

void servo1Rotate90(void) //90 Degree
{
    unsigned int i;
    for(i=0;i<10;i++)
    {
        PORTCbits.RC0 = 1;
       __delay_us(1500);
       PORTCbits.RC0 = 0;
       __delay_us(18500);
    }
}

void servo1Rotate180(void)   //180 Degree
{
    unsigned int i;
    for(i=0;i<10;i++)
    {
        PORTCbits.RC0 = 1;
       __delay_us(2200);
       PORTCbits.RC0 = 0;
       __delay_us(17800);
    }
}

void servo2Rotate0(void) //0 Degree
{
    unsigned int i;
    for(i=0;i<10;i++)
    {
       PORTCbits.RC3 = 1;
       __delay_us(800);
       PORTCbits.RC3 = 0;
       __delay_us(19200);
    }
}

void servo2Rotate90(void) //90 Degree
{
    unsigned int i;
    for(i=0;i<10;i++)
    {
        PORTCbits.RC3 = 1;
       __delay_us(1500);
       PORTCbits.RC3 = 0;
       __delay_us(18500);
    }
}

void servo2Rotate180(void)   //180 Degree
{
    unsigned int i;
    for(i=0;i<10;i++)
    {
        PORTCbits.RC3 = 1;
       __delay_us(2200);
       PORTCbits.RC3 = 0;
       __delay_us(17800);
    }
}
void writeToEEPROM(uint8_t data, uint8_t address){
    EEADR = address;
    EEDATA = data;
    
    EECON1bits.EEPGD = 0;
    EECON1bits.WREN = 1;
    
    INTCONbits.GIE = 0;
    
    EECON2 = 0x55;
    EECON2 = 0xAA;
    
    EECON1bits.WR = 1;
    
    while(PIR2bits.EEIF == 0); //Espera la escritura
    PIR2bits.EEIF = 0;
    
    EECON1bits.WREN = 0;
    INTCONbits.GIE = 1;
    return; 
}

uint8_t readFromEEPROM(uint8_t address){
    EEADR = address;
    EECON1bits.EEPGD = 0;
    EECON1bits.RD = 1;
    uint8_t data = EEDATA;
    return data;
}

//void envio_caract(char st[]){
//    int i = 0;              //Se declara una variable que recorrera la cadena
//    while (st[i] != 0){     //Mientras st no sea igual a 0
//        envio_char(st[i]);  //Se enviara el caracter por caracter
//        i++;                //Se aumenta en 1 el caracter a mostrar en la cadena
//    }
//}
//
//void envio_char(char dato){
//    while(!TXIF);           //Mientras la bandera de transmisión sea 0
//    TXREG = dato;           //Se envía el caracter
//}
