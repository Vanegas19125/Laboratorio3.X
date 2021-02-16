;*******************************************************************************
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
;*******************************************************************************

    PROCESSOR 16F887
    #include <xc.inc>
    
    ;configuration word 1
    CONFIG FOSC=INTRC_NOCLKOUT //Oscillador externo
    CONFIG WDTE=OFF	//WDT disabled (reinicio repetitivo del pic)
    CONFIG PWRTE=ON	//PWRT enabled (espera de 72ms al iniciar)
    CONFIG MCLRE=OFF	//El pin de MCLR se utiliza como I/O
    CONFIG CP=OFF	//Sin protecci[on de codigo
    CONFIG CPD=OFF	//Sin proteccion de datos

    CONFIG BOREN=OFF	//Sin reinicio cuando el voltaje de alimentacion baja 4v
    CONFIG IESO=OFF	//Reinicio sin cambio de reloj de interno a externo
    CONFIG FCMEN=OFF	//Cambio de reloj externo a interno en caso de fallo
    CONFIG LVP=ON	//programacion en bajo voltaje permitida
    
;configuration word 2
    CONFIG WRT=OFF	//Proteccion de autoescritura por el programa desactivada
    CONFIG BOR4V=BOR40V //Reinicio abajo de 4V, (BOR21v=2.1v)
    PSECT var
	CONTADOR: DS 1
	DISPLAY: DS 1
    PSECT resVect, class=CODE, abs, delta=2
;*******************************************************************************
    BSF STATUS, 6 
    BSF STATUS, 5 ; Banco 3
    CLRF ANSEL
    CLRF ANSELH
    
    BCF STATUS, 6 ; Banco 1
    CLRF TRISA ; Puerto A como salida
    CLRF TRISC ; Puerto C como salida
    
    MOVLW 255
    MOVWF TRISB ; Puerto B Como entrada
    
    BCF OPTION_REG, 7 
    BCF OPTION_REG, 5
    BCF OPTION_REG, 3
    BSF OPTION_REG, 2
    BSF OPTION_REG, 1
    BSF OPTION_REG, 0
    
    BCF STATUS, 5; Banco 0
    
    MOVLW 61
    MOVWF TMR0
    CLRF PORTA ;Poner en 0 el puerto
    CLRF PORTC ;Poner en 0 el puerto
    
    MOVLW 10
    MOVWF CONTADOR
;*******************************************************************************
    BCF INTCON, 2
;Loop General
LOOP:
    BTFSC INTCON, 2
    CALL INCCOUNT
    BTFSS PORTB, 0 ;Boton incremento contador 1
    CALL INCREMENTOC
    BTFSS PORTB, 1 ;Boton decremento contador 1
    CALL DECREMENTOC
    GOTO LOOP
;Subrutinas
    
INCCOUNT:
    BCF INTCON, 2
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
    
 INCREMENTOC:
    BTFSS PORTB, 0 ;Si se deja de presionar el boton incrementa contador 1
    GOTO $-1
    INCF DISPLAY, F
    BTFSC DISPLAY, 4 ;Instruccion para no sobrepasar los 4 bits encendidos
    DECF DISPLAY, F
    CALL TRADUCCION
    RETURN
    
 DECREMENTOC:
    BTFSS PORTB, 1 ;Si se deja de presionar el boton decrementa el contador 1
    GOTO $-1
    DECF DISPLAY, F ;decrementa puerto A
    INCFSZ DISPLAY, F ;Incrementa puerto A, si valor de F es 1
    DECF DISPLAY,F ;Decrementa puerto A y guarda valor en F
    RETURN
    
 TRADUCCION:
    MOVF DISPLAY, W
    ANDLW 00001111B
    ADDWF PCL, W
    RETLW 01111110B ; 0
    RETLW 00110000B ; 1
    RETLW 01101101B ; 2
    RETLW 01111001B ; 3
    RETLW 00110011B ; 4
    RETLW 01011011B ; 5
    RETLW 01011111B ; 6
    RETLW 01110000B ; 7
    RETLW 01111111B ; 8
    RETLW 01111011B ; 9
    RETLW 01110111B ; A
    RETLW 00011111B ; B
    RETLW 01001110B ; C
    RETLW 00111101B ; D
    RETLW 01001111B ; E
    RETLW 01000111B ; F
    RETURN
    
 END
   
   
    
    
    
    
    


