;
; Tp_1.asm
;
; Created: 13/3/2024 19:29:03
; Author : Gonza Negro 
; Microcontroladores, Mecatronica


;igualdades
.equ	softversion=0x01
.equ	build=0x04
.equ	centuria=20
.equ	anno=24
.equ	mes=3
.equ	dia=18

;**** GPIOR0 como regsitros de banderas ****
.equ LASTSTATEBTN = 0	;GPIOR0<0>: ultimo estado del pulsador
.equ BTNPRESSED = 1;GPIOR0<1>:flag de prueba para saber si pasaron 100ms 
.equ WASHERE = 2;GPIOR0<2>:  
;GPIOR0<3>:  
;GPIOR0<4>:  
;GPIOR0<5>:  
.equ ISNEWBTN     = 6	;GPIOR0<6>: cambio el estado del pulsador
.equ IS10MS	  = 7	;GPIOR0<7>: pasaron 10ms
;****


;definiciones - nombres simb?licos
.def	w=r16
.def	w1=r17
.def	saux=r18
.def	flag1=r19
.def	newButton=r21



;Segmento de EEPROM
.eseg
econfig:	.BYTE	1

;constantes
const2:		.DB 1, 2, 3


;segmento de Datos SRAM
.dseg ;reserva datos en la ram, nada mas
statboot:	.BYTE	1
t50ms:		.BYTE	1 	

addrrx:		.BYTE	2 ; variable que esta en la ram y ocupa 2 byte
RXBUF:		.BYTE	24 ; similar a array de 24b



;segmento de C?digo
.cseg
.org	0x00 ;escribe jmp start en 00
	jmp	start
.org 0x16 ; posicion del vector de interrupciones 
	jmp TIMER1_COMPA 

;interrupciones	

.org 0x34 ;inicia el programa en la posciion de memoria 36


;constantes (guardo datos en la flash para ahorrar espacio)
;consts:		.DB 0, 255, 0b01010101, -128, 0xaa
;varlist:	.DD 0, 0xfadebabe, -2147483648, 1 << 30


;Servicio de interrupciones
;serv_rx0:
;	reti

;serv_cmp0:
;	reti



;**** Funciones ****
TIMER1_COMPA:
	push	r2
	in	r2, SREG
	push	r2
	push	r16
	push	r17
	push	r24
	push	r25 ; salva el estado cuando se realiza la interrupcion 
	;Hago lo que tengo que hacer
	sbi GPIOR0,IS10MS; PONGO LA FLAG EN 1 

out_TIMER1_OVF:
	pop	r25; al salir devuelve a todo el estado que tenia antes de que se salte la interrupcion 
	pop	r24
	pop	r17
	pop	r16
	pop	r2
	out	SREG, r2
	pop	r2
	reti

;PORTB

ini_ports:
	ldi r16,0b00100000
	out DDRB,r16 ; para La salida PB5
	mov r0,r16
	ldi r17,0b00010000
	out PORTB,r17 ; para el pulsador ENTRADA PB4
	
	ret
ini_timer1:; para inicializar al timer 
	ldi	r16, 0x00
	sts	TCCR1A, r16
	ldi r16,high(625)
	sts OCR1AH,r16 ; parte alta del comparador
	ldi r16,low(625)
	sts OCR1AL,r16 ; parte baja del comparador 
	ldi	r16, 0b00000010; habilita el compare A 
	sts	TIMSK1, r16
	lds	r16, TIFR1; CONSULTAR SUPONGO SALVA ESTADO TIFR1
	sts	TIFR1, r16
	
	ldi r16,0b00001100
	sts TCCR1B,r16; setea el timer como CTC preescalado 256
	ret

;rutinas matematicas
;(R15:R14)/(R13:R12) = (R15:R14) rest (R11:R10) 

div16u: ;
	push	r16
	clr	r10
	clr	r11
	ldi	r16, 17
	clc	
d16u_1: ;
	rol	r14
	rol	r15
	dec	r16
	brne	d16u_2
	pop	r16
	ret
d16u_2: ;
	rol	r10
	rol	r11
	sub	r10, r12
	sbc	r11, r13
	sbrs	r11, 7
	rjmp	d16u_3	
	add	r10, r12
	adc	r11, r13
	clc	
	rjmp	d16u_1
d16u_3:;
	sec	
	rjmp	d16u_1

ini_serie0:
	ret

do10ms:
	cbi GPIOR0, IS10MS ; RESETEA la FLAG DE LOS 10ms
	lds r16,t50ms;
	dec r16; le resta uno a t100ms
	sts t50ms,r16;lo devuelve
	brne	PC+2 ; si es no es igual a 0 hace un branch del PC+2 sino hace el rjump
	rjmp	testDbBtn; va a testDbBtn
	ret
testDbBtn:; procedimiento para hacer el debounce 
	ldi	r16, 5 ; pone 10 en el r16
	sts t50ms,r16; resetea la variable de los 100ms 
	sbic GPIOR0,BTNPRESSED; si la flag esta sin hacer,skip
	rjmp buttonDown; si la flag esta hecha 
	rjmp buttonUp; va a buttonUp		

buttonDown:; si ya salto un ciclo y paso por falling entra a down  
	 sbic PINB,PB4 ; si el PB5 sigue en bajo hace skip
	 rjmp buttonUp		
	;si hizo skip significa que el PB5 sigue abajo (boton presionado)						
	sbic GPIOR0,WASHERE;pregunta si ya estuvo aqui 
	ret;
	sbis GPIOR0,ISNEWBTN; SI LA FLAG ESTA SIN hacer	  
	sbi GPIOR0,ISNEWBTN; setea la flag de hacer algo 
	sbi GPIOR0,WASHERE;
	ret;sale 
		
buttonFalling:; entra si el PB5 esta en bajo
	sbi GPIOR0,BTNPRESSED;setea la flag y sale
	ret  
	
buttonUp: ; viene si la flag button esta en 0
	sbis PINB,PB4; salta si el PB5 esta hecho (BOTON SIN PRESIONAR)  
	rjmp buttonFalling; (SI ESTA PRESIONADO SALTA A FALLING)
	cbi GPIOR0,BTNPRESSED;pone la flag en 0 y sale  
	cbi GPIOR0,WASHERE; (RESETEA LA FLAG DE QUE YA PASO POR BUTTONDOWN)
ret	


;Like a main in C
start:
	cli
	call	ini_ports
	;call	ini_serie0
	call	ini_timer1; llama al que inicializa el timer 
	cbi GPIOR0,IS10MS
	ldi r16,5
	sts t50ms,r16; inicializa t100ms en 10 
	sei
loop:					
	sbis GPIOR0,IS10MS	
	jmp loop
	call do10ms
	sbic GPIOR0,ISNEWBTN;PREGUNTA POR LA FLAG DE HACER ALGO
	call toggleLed; HACE TOGGLE
	cbi GPIOR0,ISNEWBTN; (RESETEA LA FLAG DE HACER ALGO, POR SI YA SE VOLVIO A SOLTAR EL BOTON )
	jmp loop

toggleLed:; subrutina para cambiar el estado del led 
	in r16,PORTB
	eor r16,r0
	out PORTB,r16
ret

