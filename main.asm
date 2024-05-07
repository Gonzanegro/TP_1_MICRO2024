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
.equ	M=0x4D ;77
.equ	O=0x4F;79
.equ	D=0x44;68
.equ	N0=0x30;48
.equ	N1=0x31;49
.equ	N2=0x32;50
.equ	N3=0x33;51
.equ	N4=0x34;52
.equ	N5=0x35;53
.equ	N6=0x36;54
.equ	N7=0x37;55
.equ	N8=0x38;56
.equ	N9=0x39;57
.equ	NULL =0x00;0
;**** GPIOR0 como regsitros de banderas ****
.equ LASTSTATEBTN = 0	;GPIOR0<0>: ultimo estado del pulsador
.equ BTNPRESSED = 1;GPIOR0<1>:flag de prueba para saber si pasaron 100ms 
.equ DATAREADY = 2;GPIOR0<2>: flag que uso para las subrutinas de enviar datos   
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
t50ms:		.BYTE	1 ;variable que se resetea cada 50ms	
state:		.BYTE	1 ;variable para hacer switch entre estados 
addrrx:		.BYTE	2 ; variable que esta en la ram y ocupa 2 byte
TXBUF:		.BYTE	8 ; voy a utilizar 6 bytes para poner "MODO 0-10" 
RXBUF:		.BYTE	24 ; similar a array de 24b
indexTx:	.BYTE	1 ; variable para el indice del buffer de transmision 


;segmento de C?digo
.cseg
.org	0x00 ;escribe jmp start en 00
	jmp	start
.org 0x16 ; posicion del vector de interrupciones 
	jmp TIMER1_COMPA 

;interrupciones	

.org 0x34 ;inicia el programa en la posciion de memoria 36

;**** Constantes en FLASH ****
;PONGO EL VALOR EN ASCII DE LAS LETRAS QUE VOY A USAR PARA LA TRANSMISION 
;M:	.DB 0x4D ;77
;O:	.DB 0x4F;79
;D:	.DB 0x44;68
;N0:	.DB 0x30;48
;N1:	.DB 0x31;49
;N2:	.DB 0x32;50
;N3:	.DB 0x33;51
;N4:	.DB 0x34;52
;N5:	.DB 0x35;53
;N6:	.DB 0x36;54
;N7:	.DB 0x37;55
;N8:	.DB 0x38;56
;N9:	.DB 0x39;57
;NULL: .DB 0x00;0

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

ini_ports:;inicializa la GPIO
	ldi r16,0b00100000
	out DDRB,r16 ; para La salida PB5
	mov r0,r16
	ldi r17,0b00010000
	out PORTB,r17 ; para el pulsador ENTRADA PB4	
	ret
ini_serie0: ; inicializa la usart0 
	; de esta forma se inicializa la USART en modo transmision para 8 bits de datos a 115200 bps (U2X0 en 1 y UBBRN en 16) con cristal de 16MHz
	ldi	r16, (1 << U2X0) ;carga en el r16 1 desplazado a U2X0 ese bit va en 1 para doblar la velocidad en transmision asincrona
	sts	UCSR0A, r16 ; pone ese bit en 1 en el UCSR0A para
	ldi	r16, (1 << TXEN0) ; pone en r16 en 1 el bit desplazado TXEN0 este bit habilita la transmision 
	sts	UCSR0B, r16 ; lo carga en UCSR0B
	ldi	r16, (1 << UCSZ01) | (1 << UCSZ00) ; define el formato de los datos a enviar en este caso 8 bits
	sts	UCSR0C, r16 ; pone en 1 los bit UCSZ01 y UCSZ00 del USR0C
	ldi	r16, 16
	sts	UBRR0L, r16 ; Pone el UBRR0L en 0001 0000 (para setear el baudrate)
	clr	r16
	sts	UBRR0H, r16 ; pone el UBRR0H en cero (del b12 al 15 son reservados) 
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


do10ms:
	cbi GPIOR0, IS10MS ; RESETEA la FLAG DE LOS 10ms
	lds r16,t50ms;
	dec r16; le resta uno a t50ms
	sts t50ms,r16;lo devuelve
	brne	PC+2 ; si es no es igual a 0 hace un branch del PC+2 sino hace el rjump
	rjmp	testDbBtn; va a testDbBtn
	ret
testDbBtn:; procedimiento para hacer el debounce 
	ldi	r16, 5 ; pone 5 en el r16
	sts t50ms,r16; resetea la variable de los 50ms 
	
	sbic GPIOR0,BTNPRESSED;si la flag esta hecha va a Down, sino salta a ver el estado del boton 
	rjmp buttonDown; 
	sbis PINB,PB4; si el boton esta sin presionar salta a button up
	rjmp buttonFalling;		si esta presionado salta a falling
	rjmp buttonUp;

buttonRising:
	cbi GPIOR0,BTNPRESSED ; resetea la flag de pressed	
	sbi GPIOR0,ISNEWBTN ;setea la flag de evento 
	ret
buttonDown:; si ya salto un ciclo y paso por falling entra a down  
	sbis PINB,PB4;si el pulsador cambio de estado va a rising 
	ret;sino hace ret y queda atrapado aca 
	rjmp buttonRising
buttonFalling:; entra si el PB5 esta en bajo
	sbi GPIOR0,BTNPRESSED;setea la flag
	ret   	
buttonUp: ; viene si la flag button esta en 0
	sbic GPIOR0,BTNPRESSED
	cbi GPIOR0,BTNPRESSED;pone la flag en 0 y sale  
ret	
changeMode:
	lds r17,state; carga en el r17 el estado igual
	inc r17; incrementa en 1 la variable de estado  
	sts state,r17;lo devuelve
	ldi r18,11;carga el r18 en 11 para ver si se desbordo el modo 
	cp r17,r18
	brne PC+5 ; si es son iguales hace un branch del PC+5 sino resetea la variable antes de salir 
	ldi r17,0
	sts state,r17;
	rjmp iddle;salta al estado 0
	;comparacion para ver en que estado se encuentra ahora y enviar el mensaje 
	;;FUNCIONA COMO UNA MEF
	lds r17,state; carga en el r17 el estado nuevo
	ldi r18,1;pone el r18 en 1 
	cp r17,r18; compara el modo con 1 
	brne PC+2 ; si no son iguales incrementa el PC en 2 
	rjmp state1; si son iguales va a state 1 
	
	ldi r18,2;pone el r18 en 2 
	cp r17,r18; compara el modo con 2 
	brne PC+2 ; si no son iguales incrementa el PC en 2 
	rjmp state2; si son iguales va a state 1 
	
	ldi r18,3;pone el r18 en 3 
	cp r17,r18; compara el modo con 3 
	brne PC+2 ; si no son iguales incrementa el PC en 2 
	rjmp state3; si son iguales va a state 3 
	
	ldi r18,4;pone el r18 en 4 
	cp r17,r18; compara el modo con 4 
	brne PC+2 ; si no son iguales incrementa el PC en 2 
	rjmp state4; si son iguales va a state 4 
	
	ldi r18,5;pone el r18 en 5 
	cp r17,r18; compara el modo con 5 
	brne PC+2 ; si no son iguales incrementa el PC en 2 
	rjmp state5; si son iguales va a state 5 
	
	ldi r18,6;pone el r18 en 6 
	cp r17,r18; compara el modo con 6 
	brne PC+2 ; si no son iguales incrementa el PC en 2 
	rjmp state6; si son iguales va a state 6 
	
	ldi r18,7;pone el r18 en 7 
	cp r17,r18; compara el modo con 7 
	brne PC+2 ; si no son iguales incrementa el PC en 2 
	rjmp state7; si son iguales va a state 7 
	
	ldi r18,8;pone el r18 en 8 
	cp r17,r18; compara el modo con 8 
	brne PC+2 ; si no son iguales incrementa el PC en 2 
	rjmp state8; si son iguales va a state 8 
	
	ldi r18,9;pone el r18 en 9 
	cp r17,r18; compara el modo con 9 
	brne PC+2 ; si no son iguales incrementa el PC en 2 
	rjmp state9; si son iguales va a state 9 
	
	ldi r18,10;pone el r18 en 10
	cp r17,r18; compara el modo con 10 
	brne PC+2 ; si no son iguales incrementa el PC en 2 
	rjmp state10; si son iguales va a state 10
	
	state1: ;carga el buffer con el 1 en la poscion de modo y luego sale 
	ldi r19,N1;pone el N1
	sts TXBUF+4,r19; carga en el buffer
	ldi r19,'\n' ; para el final de linea 
	sts TXBUF+5,r19
	sbi GPIOR0,DATAREADY; setea la flag para la transmision antes de salir 
	ldi r19,0
	sts indexTx,r19 ; pone en cero el indice del buffer de transmision 
	ret
	state2:
	ldi r19,N2;pone el N2
	sts TXBUF+4,r19; carga en el buffer
	ldi r19,'\n' ; para el final de linea 
	sts TXBUF+5,r19
	sbi GPIOR0,DATAREADY; setea la flag para la transmision antes de salir 
	ldi r19,0
	sts indexTx,r19 ; pone en cero el indice del buffer de transmision 
	ret
	state3:
	ldi r19,N3;pone el N3
	sts TXBUF+4,r19; carga en el buffer
	ldi r19,'\n' ; para el final de linea 
	sts TXBUF+5,r19
	sbi GPIOR0,DATAREADY; setea la flag para la transmision antes de salir 
	ldi r19,0
	sts indexTx,r19 ; pone en cero el indice del buffer de transmision 
	ret
	state4:
	ldi r19,N4;pone el N4
	sts TXBUF+4,r19; 
	ldi r19,'\n' ; para el final de linea 
	sts TXBUF+5,r19
	sbi GPIOR0,DATAREADY; setea la flag para la transmision antes de salir 
	ldi r19,0
	sts indexTx,r19 ; pone en cero el indice del buffer de transmision 
	ret
	state5:
	ldi r19,N5;pone el N5
	sts TXBUF+4,r19; 
	ldi r19,'\n' ; para el final de linea 
	sts TXBUF+5,r19
	sbi GPIOR0,DATAREADY; setea la flag para la transmision antes de salir 
	ldi r19,0
	sts indexTx,r19 ; pone en cero el indice del buffer de transmision 
	ret
	state6:
	ldi r19,N6;pone el N6
	sts TXBUF+4,r19; 
	ldi r19,'\n' ; para el final de linea 
	sts TXBUF+5,r19
	sbi GPIOR0,DATAREADY; setea la flag para la transmision antes de salir 
	ldi r19,0
	sts indexTx,r19 ; pone en cero el indice del buffer de transmision 
	ret
	state7:
	ldi r19,N7;pone el N7
	sts TXBUF+4,r19; 
	ldi r19,'\n' ; para el final de linea 
	sts TXBUF+5,r19
	sbi GPIOR0,DATAREADY; setea la flag para la transmision antes de salir 
	ldi r19,0
	sts indexTx,r19 ; pone en cero el indice del buffer de transmision 
	ret
	state8:
	ldi r19,N8;pone el N8
	sts TXBUF+4,r19
	ldi r19,'\n' ; para el final de linea 
	sts TXBUF+5,r19
	sbi GPIOR0,DATAREADY; setea la flag para la transmision antes de salir 
	ldi r19,0
	sts indexTx,r19 ; pone en cero el indice del buffer de transmision 
	ret
	state9:
	ldi r19,N9;pone el N9
	sts TXBUF+4,r19; carga al buffer
	ldi r19,'\n' ; para el final de linea 
	sts TXBUF+5,r19
	sbi GPIOR0,DATAREADY; setea la flag para la transmision antes de salir 
	ldi r19,0
	sts indexTx,r19 ; pone en cero el indice del buffer de transmision 
	ret
	state10: ; carga el 1 y el 0 
	ldi r19,N1;pone el N1
	sts TXBUF+4,r19; pone el 1 en el buffer
	ldi r19,N0
	sts TXBUF+5,r19;carga 0 en el buffer
	ldi r19,'\n' ; para el final de linea 
	sts TXBUF+6,r19
	sbi GPIOR0,DATAREADY; setea la flag para la transmision antes de salir 
	ldi r19,0
	sts indexTx,r19 ; pone en cero el indice del buffer de transmision 
	ret
	iddle: ; vuelve a poner el 0 delante y NULL atras 
	ldi r19,N0;pone el N1
	sts TXBUF+4,r19; carga el cero en el buffer 
	ldi r19,'\n' ; para el final de linea 
	sts TXBUF+5,r19
	ldi r19,NULL ; final de la cadena de caracteres  
	sts TXBUF+6,r19
	sbi GPIOR0,DATAREADY; setea la flag para la transmision antes de salir 
	ldi r19,0
	sts indexTx,r19 ; pone en cero el indice del buffer de transmision 
	ret
;Like a main in C


start:
	cli
	call	ini_ports
	call	ini_serie0 ; inicializa el puerto serie 0 
	call	ini_timer1; llama al que inicializa el timer 
	cbi GPIOR0,IS10MS
	ldi r16,5
	sts t50ms,r16; inicializa t100ms en 10 
	ldi r16,0 ;pone en 0 el r16
	sts state,r16; inicializa el estado en 0 
	;;CARGA EL BUFFER DE TRANSMISION CON MODO (CONSTANTES SIEMPRE) Y pone el 0 
	ldi r16,M;
	ldi r17,O
	ldi r18,D
	ldi r19,N0
	sts TXBUF+0,r16 ;pone la M al inicio
	sts TXBUF+1,r17;la o 
	sts TXBUF+2,r18; la d
	sts TXBUF+3,r17;la o de vuelta 
	sts TXBUF+4,r19; pone el 0
	ldi r16,NULL
	sts TXBUF+5,r16;pone null en el 6to byte 
	sts TXBUF+6,r16;los dos que guarde por las dudas 
	sts TXBUF+7,r16
	;;termina de cargar el buffer 

	sei
loop:					
	sbis GPIOR0,IS10MS	
	jmp loop
	call do10ms
	sbic GPIOR0,ISNEWBTN;PREGUNTA POR LA FLAG DE HACER ALGO
	call changeMode; llama a cambiar de modo
	cbi GPIOR0,ISNEWBTN
sendDataTx:
	sbis GPIOR0,DATAREADY; si la flag DATAREADY ESTA HECHA sigue, sino loop  
	jmp loop
	
	lds	r16, UCSR0A ; trae UCSR0A desde flash 
	sbrs	r16, UDRE0 ; se fija si esya hecho el bit UDRE0 en UCSR0A (este bit esta en alto si el registro de datos esta vacío)
	jmp	loop ; si ese bit esta en bajo hace loop 

	sbr	r16, TXC0 ; pobe en alto el bit TXC0 de r16 (TXC es la flag de transmision completada)
	sts	UCSR0A, r16 ; pone en UCSR0A el r16 con el bit TXC0 en alto 
	;comienzo de transmision 
	lds r17,indexTx
	;segun el indice carga el byte del buffer que tiene que enviar  
	ldi r18,0;
	cp r17,r18
	brne PC+4
	lds r16,TXBUF+0;
	rjmp ReadyBuf
	ldi r18,1;
	cp r17,r18
	brne PC+4
	lds r16,TXBUF+1;
	rjmp ReadyBuf
	ldi r18,2;
	cp r17,r18
	brne PC+4
	lds r16,TXBUF+2;
	rjmp ReadyBuf
	ldi r18,3;
	cp r17,r18
	brne PC+4
	lds r16,TXBUF+3;
	rjmp ReadyBuf
	ldi r18,4;
	cp r17,r18
	brne PC+4
	lds r16,TXBUF+4;
	rjmp ReadyBuf
	ldi r18,5;
	cp r17,r18
	brne PC+4
	lds r16,TXBUF+5;
	rjmp ReadyBuf
	ldi r18,6;
	cp r17,r18
	brne PC+4
	lds r16,TXBUF+6;
	rjmp ReadyBuf
	ldi r18,7;
	cp r17,r18
	brne PC+4
	lds r16,TXBUF+7;
	rjmp ReadyBuf

ReadyBuf:
	sts	UDR0, r16 ;manda el r16 a UDR0 para hacer la transmision 
	inc r17; incrementa en 1 r15 para luego pasarselo al indice 
	sts indexTx,r17 ; queda incrementada la variable del indice 
	ldi r18,'\n';
	cp r16,r18; compara el byte que acaba de enviar con '\n'
	breq PC+2 ; si son iguales salta a readyDataTx
	jmp loop;
readyDataTx:
	
	cbi GPIOR0,DATAREADY; resetea la flag 
	
	jmp loop ; hace loop

