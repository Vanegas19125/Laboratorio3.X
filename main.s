;-------------------------------------------------------------------------------
    ;Archivo:	  main.s
    ;Dispositivo: PIC16F887
    ;Autor: José Vanegas
    ;Compilador: pic-as (v2.30), MPLABX V5.45
    ;
    ;Programa: Timer y contador Hexadecimal
    ;Hardware: Display 7 Seg, Push Buttom, Leds, Resistencias. 
    ;
    ;Creado: 16 feb, 2021
    ;Última modificación: 16 feb, 2021    
;-------------------------------------------------------------------------------

    PROCESSOR 16F887
    #include <xc.inc>
    
    
    CONFIG FOSC=INTRC_NOCLKOUT //Oscillador interno
    CONFIG WDTE=OFF	//WDT disabled (reinicio repetitivo del pic)
    CONFIG PWRTE=ON	//PWRT enabled (espera de 72ms al iniciar)
    CONFIG MCLRE=OFF	//El pin de MCLR se utiliza como I/O
    CONFIG CP=OFF	//Sin protecci[on de codigo
    CONFIG CPD=OFF	//Sin proteccion de datos

    CONFIG BOREN=OFF	//Sin reinicio cuando el voltaje de alimentacion baja 4v
    CONFIG IESO=OFF	//Reinicio sin cambio de reloj de interno a externo
    CONFIG FCMEN=OFF	//Cambio de reloj externo a interno en caso de fallo
    CONFIG LVP=ON	//programacion en bajo voltaje permitida
    

    CONFIG WRT=OFF	//Proteccion de autoescritura por el programa desactivada
    CONFIG BOR4V=BOR40V //Reinicio abajo de 4V, (BOR21v=2.1v)
    
    //Creamos variables para el antirebote, para el display y para el contador 
    //del timer
    PSECT udata_bank0
	CONTADOR: DS 1
	DISPLAY: DS 1
	DELAY: DS 1
	PORTB_ANTERIOR: DS 1  
	PORTB_ACTUAL: DS 1        	
    
    PSECT resVect, class=CODE, abs, delta=2
;-------------------------------------------------------------------------------
    BSF STATUS, 6 
    BSF STATUS, 5 ; Banco 3
    CLRF ANSEL
    CLRF ANSELH
    
    BCF STATUS, 6 ; Banco 1
    CLRF TRISA ; Puerto A como salida
    CLRF TRISC ; Puerto C como salida
    CLRF TRISD ; Puerto D como salida
    
    MOVLW 255
    MOVWF TRISB ; Puerto B Como entrada
    
    BCF OPTION_REG, 7 ;Habilitamos los pull ups del puerto B
    BCF OPTION_REG, 5 ;Bit 5 en 0 para usar internal instruction cycle clock
    BCF OPTION_REG, 3 ;Bit 3 en 0 para asignarle un preescaler
    BSF OPTION_REG, 2 ;Configuramos los bits 2, 1, 0 para un preescaler de 256
    BSF OPTION_REG, 1
    BSF OPTION_REG, 0
    
    BCF STATUS, 5; Banco 0
    MOVLW 61	;Movemos el 61 a W
    MOVWF TMR0	;y ese valor lo movemos al TMR0, que es la resta de 256-N
    CLRF PORTA ;Poner en 0 el puerto A
    CLRF PORTC ;Poner en 0 el puerto C
    CLRF PORTD ;Poner en 0 el puerto D
    
    MOVLW 10
    MOVWF CONTADOR  ;Asignamos un valor de 10 al contador del timer
    
    MOVLW 255
    MOVWF  PORTB_ACTUAL
    MOVWF  PORTB_ANTERIOR
    BCF INTCON, 2
;---------------------------Loop General----------------------------------------
    
LOOP:
    MOVF    PORTB_ACTUAL, W
    MOVWF   PORTB_ANTERIOR
    CALL    delay_small
    MOVF    PORTB,W
    MOVWF   PORTB_ACTUAL   ;implementacion del antirebote lineas 83-87
    BTFSC INTCON, 2
    CALL INCCOUNT	  ;Llamamos a la subrutina incremento contador timer
    BTFSS PORTB_ANTERIOR, 0 ;Boton incremento hexadecimal
    CALL INCREMENTOC
    BTFSS PORTB_ANTERIOR, 1 ;Boton decremento contador hexadecimal
    CALL DECREMENTOC
;-----------------Muestra el contador de botones en el display------------------
    CALL TRADUCCION	;Llamamos la sub traduccion para pasar el numero binari
    //del contador y pasarlo a hexadecimal
    MOVWF PORTC	    ;ese valor lo movemos al puerto C donde esta el display
;------------------------------Comparacion -------------------------------------
    ;Realizamos la comparacion entre el contador del timer y el hexadecimal
    ;para verificar si su valor es igual yy reiniciar el timer
    MOVF PORTA, W
    SUBWF DISPLAY, W
    BTFSC STATUS, 2
    BSF PORTD, 0
    BTFSS STATUS, 0
    CALL ALARMA
    GOTO LOOP
;Subrutinas
ALARMA:		    ;Subrutina para encender el LED de alarma
    CLRF PORTA
    BCF PORTD,0
    RETURN
INCCOUNT:	    ;subrutina para decrementar el contador del timer hasta
    BCF INTCON, 2   ;que su valor sea 0, significa que ya pasaron los 500 ms
    MOVLW 61
    MOVWF TMR0
    DECFSZ CONTADOR, F
    RETURN
    MOVLW 10
    MOVWF CONTADOR
    INCF PORTA, F
    MOVLW 16
    SUBWF PORTA, W
    BTFSS STATUS, 2
    RETURN
    CLRF PORTA
    RETURN
    
 INCREMENTOC:	    ;subrutina para incrementar el contador hexadecimal
    BTFSS  PORTB_ACTUAL, 0
    RETURN
    INCF DISPLAY, F
    BTFSC DISPLAY, 4 ;Instruccion para no sobrepasar los 4 bits encendidos
    DECF DISPLAY, F
    RETURN
    
 DECREMENTOC:	    ;subrutina para decrementar el contador hexadecimal
    BTFSS PORTB_ACTUAL, 1
    RETURN
    DECF DISPLAY, F ;decrementa puerto A
    INCFSZ DISPLAY, F ;Incrementa puerto A, si valor de F es 1
    DECF DISPLAY,F ;Decrementa puerto A y guarda valor en F
    RETURN
    
 TRADUCCION:	;subrutina para traducir el valor binario del contador, a hexa-
    ;decimal en el display
    MOVF DISPLAY, W 
    ANDLW 00001111B
    ADDWF PCL, F
    RETLW 00111111B ; 0
    RETLW 00000110B ; 1
    RETLW 01011011B ; 2
    RETLW 01001111B ; 3
    RETLW 01100110B ; 4
    RETLW 01101101B ; 5
    RETLW 01111101B ; 6
    RETLW 00000111B ; 7
    RETLW 01111111B ; 8
    RETLW 01101111B ; 9
    RETLW 01110111B ; A
    RETLW 01111100B ; B
    RETLW 00111001B ; C
    RETLW 01011110B ; D
    RETLW 01111001B ; E
    RETLW 01110001B ; F

 delay_small: ;subrutina para un pequeño delay en los antirebotes de los botones
    movlw   167		    ;valor inicial del contador 
    movwf   DELAY	    ;(valor-1)*3 uS + 2 uS = 500 us
    decfsz  DELAY, F   ;decrementar el contador
    goto    $-1		    ;ejecutar linea anterior
    return	
 END