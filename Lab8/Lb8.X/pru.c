/*
 * File:   ADC.c
 * Author: SAGASTUME
 *
 * Created on 2 de febrero de 2021, 11:46 PM
 */

#include<stdint.h>
#include <xc.h>
#define _XTAL_FREQ 8000000
uint8_t flag;


void ADC_con(uint8_t flag) {
   
    ADCON1bits.ADFM = 0;
    ANSEL = 0b00000001;
    INTCON = 0b11101000;
    ADCON0 = 0b01000001;
    //INTCON = 0b11101000;
    PIE1bits.ADIE = 1;
    PIR1bits.ADIF = 0;
    if (flag == 1) {
        __delay_us(20);
        ADCON0bits.GO = 1;
        flag = 0;
        

    }


/*
 * File:   Carrera.c
 * Author: Cristopher Sagastume 18640
 *
 * Created on 29 de enero de 2021, 08:46 AM
 */
//**************************
// PALABRA DE CONFIGURACIÓN
//**************************

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
#pragma config LVP = OFF        // Low Voltage Programming Enable bit (RB3 pin has digital I/O, HV on MCLR must be used for programming)

// CONFIG2
#pragma config BOR4V = BOR40V   // Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
#pragma config WRT = OFF        // Flash Program Memory Self Write Enable bits (Write protection off)

// #pragma config statements should precede project file includes.
// Use project enums instead of #define for ON and OFF.
#include<stdint.h>
#include <xc.h>
#include "ADC.h"
#include "Multiplexado.h"

//**************************
//  Variables
//**************************
uint8_t count;
uint8_t flag = 1;
uint8_t valor_MSB;
uint8_t valor_LSB;
uint8_t comparacion;
uint8_t seg1;
uint8_t seg2; //0             1           2           3           4           5           6           7           8           9           A             B             C         D         E           F           
uint8_t tabla_7seg[] = {0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110, 0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01101111, 0b01110111, 0b01111100, 0b00111001, 0b01011110, 0b01111001, 0b01110001};
#define _XTAL_FREQ 8000000


//**************************
//  Prototipo de funciones
//**************************
void setup(void);
void __interrupt() ISR(void);


//**************************
//  Ciclo Principal
//**************************

void main(void) {
    setup();
    count = 0;
    flag = 1;
    Multiplex();
    while (1) {
        ADC_con(flag);
        PORTD = count;
        //PORTC=seg1;
        //PORTC=seg2;
        seg1 = tabla_7seg[valor_MSB];
        seg2 = tabla_7seg[valor_LSB];
        if (comparacion > count) {
            PORTBbits.RB0 = 1;
        } else {
            PORTBbits.RB0 = 0;
        }
    }

}


//**************************
//  Configuración
//**************************

void setup(void) {
    TRISD = 0b00000000;
    TRISC = 0b00000000;
    TRISB = 0b11111110;
    TRISE = 0b00000000;
    //    ANSEL = 0b00000001;
    //    INTCON = 0b11101000;
    //    ADCON0 = 0b01000001;
    //IOCBbits.IOCB0 = 1;
    //IOCBbits.IOCB1 = 1;
    IOCBbits.IOCB6 = 1;
    IOCBbits.IOCB7 = 1;
    PORTB = 0;
    PORTC = 0;
    PORTD = 0;
    PORTE = 0;
    PORTEbits.RE0 = 1;
    //INTCONbits.RBIF = 0;
    //INTCONbits.T0IF	 = 0;
}


//**************************
//  Funciones
//**************************

void __interrupt() ISR(void) {
    if (INTCONbits.T0IF == 1) {
        TMR0 = 10;
        if (PORTEbits.RE0 == 1) {
            PORTEbits.RE0 = 0;
            PORTEbits.RE1 = 1;
            PORTC = seg2;
        } else if (PORTEbits.RE1 == 1) {
            PORTEbits.RE1 = 0;
            PORTEbits.RE0 = 1;
            PORTC = seg1;
        }
        INTCONbits.T0IF = 0;
    }
    if (PIR1bits.ADIF == 1) {
        flag = 1;
        valor_MSB = ADRESH >> 4; // 11110000 --->  00001111
        valor_LSB = ADRESH & 0b00001111; //   01010101 ---> 00000101
        comparacion = ADRESH;
        PIR1bits.ADIF = 0;
    }
    if (INTCONbits.RBIF == 1) {
        if (PORTBbits.RB6 == 0) {
            count++;
            //PORTD = count;
        } else if (PORTBbits.RB7 == 0) {
            count--;
            //PORTD = count;
        }
        INTCONbits.RBIF = 0;
    }
}