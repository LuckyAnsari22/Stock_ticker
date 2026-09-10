; ==============================================================================
; uart_price_receiver.asm
; 8051 Assembly Module for MPMC Mini Project (Unit 5 & 6 compliance)
;
; Purpose: Demonstrates syllabus mapping for CO3 (Serial I/O, Interrupts, 
;          Timers, Register Banks, Context Switching) in pure assembly.
;
; Description: 
; 1. Initializes UART to 9600 baud 8N1 using Timer 1 Mode 2.
; 2. Uses Serial Interrupt (0023H) to receive data without polling loop.
; 3. Uses PUSH/POP for context saving.
; 4. Switches register banks to protect main loop variables.
; 5. Compares incoming 8-bit price payload to a hardcoded threshold.
; 6. Toggles P1.0 (Alert LED) and P1.1 (Safe LED) based on threshold logic.
; ==============================================================================

ORG 0000H
    LJMP MAIN

ORG 0023H          ; Serial Interrupt Vector (Lecture 33)
    LJMP SERIAL_ISR

ORG 0050H
MAIN:
    ; --- STEP 1: Initialize UART & Timers ---
    MOV TMOD, #20H     ; Timer 1, Mode 2 (8-bit auto-reload, Lecture 32)
    MOV TH1, #0FDH     ; 9600 baud rate (assuming 11.0592 MHz crystal)
    MOV SCON, #50H     ; SCON: Mode 1 (8-bit UART), REN=1 (enable receiver)
    SETB TR1           ; Start Timer 1
    
    ; --- STEP 2: Enable Interrupts ---
    MOV IE, #10010000B ; EA=1, ES=1 (Enable Global & Serial Interrupts)
    
WAIT_LOOP:
    ; Microcontroller is free to do other tasks here.
    ; Real-time responsiveness is driven by the ISR.
    SJMP WAIT_LOOP     

; ==============================================================================
; SERIAL INTERRUPT SERVICE ROUTINE (Syllabus: Context Switching, Bank Selection)
; ==============================================================================
SERIAL_ISR:
    ; Context Save
    PUSH ACC           
    PUSH PSW           

    ; Switch to Register Bank 1 for ISR operations
    SETB RS0           
    CLR RS1            

    JB RI, READ_DATA   ; Check if it was a Receive Interrupt (RI)
    
    ; It was a Transmit Interrupt (TI), clear it.
    CLR TI             
    SJMP ISR_EXIT

READ_DATA:
    CLR RI             ; Clear RI flag to prepare for next byte
    MOV A, SBUF        ; Read the serial byte into Accumulator
    
    ; --- Threshold Logic (Syllabus: Arithmetic/Conditionals Chapter 4) ---
    ; Let's assume we receive an 8-bit packed price threshold or alert code
    ; If A >= 100 (0x64), Trigger Alert
    
    CJNE A, #100, COMPARE
COMPARE:
    JC BELOW_THRESH    ; If A < 100, Carry Flag (CY) is set, jump to Safe
    
ABOVE_THRESH:
    ; Situation: Actionable Signal (e.g. BUY/SELL alert)
    SETB P1.0          ; P1.0 = High (Alert LED ON)
    CLR P1.1           ; P1.1 = Low  (Safe LED OFF)
    SJMP ISR_EXIT
    
BELOW_THRESH:
    ; Situation: Normal running
    CLR P1.0           ; P1.0 = Low  (Alert LED OFF)
    SETB P1.1          ; P1.1 = High (Safe LED ON)
    
ISR_EXIT:
    ; Context Restore
    CLR RS0            ; Return to Register Bank 0
    POP PSW            
    POP ACC            
    RETI               ; Return from Interrupt

END
