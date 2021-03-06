;*******************************************************************
; main.s
; Author: Quinn Kleinfelter
; Date Created: 10/13/2020
; Last Modified: 10/13/2020
; Section Number: 001/003
; Instructor: Devinder Kaur / Suba Sah
; Lab number: 4
;   Brief description of the program
; The overall objective of this system is an interactive alarm
; Hardware connections
;   PF4 is switch input  (1 = switch not pressed, 0 = switch pressed)
;   PF3 is LED output    (1 activates green LED) 
; The specific operation of this system 
;   1) Make PE0 an output and make PE1 an input. 
;   2) The system starts with the LED ON (make PE0 = 1). 
;   3) Delay for about 62 ms
;   4) If the switch is pressed (PE1 is 1),
;      then toggle the LED once, else turn the LED ON. 
;   5) Repeat steps 3 and 4 over and over
;*******************************************************************

GPIO_PORTE_DATA_R       EQU   0x400243FC
GPIO_PORTE_DIR_R        EQU   0x40024400
GPIO_PORTE_AFSEL_R      EQU   0x40024420
GPIO_PORTE_DEN_R        EQU   0x4002451C
GPIO_PORTE_AMSEL_R      EQU   0x40024528
GPIO_PORTE_PCTL_R       EQU   0x4002452C
SYSCTL_RCGCGPIO_R       EQU   0x400FE608

	   IMPORT  TExaS_Init

       AREA    |.text|, CODE, READONLY, ALIGN=2
       THUMB
       EXPORT  Start
Start
	; TExaS_Init sets bus clock at 80 MHz
	BL  TExaS_Init 
	
InitPortE
	; SYSCTL_RCGCGPIO_R = 0x10
	MOV R0, #0x10
	LDR R1, =SYSCTL_RCGCGPIO_R
	STR R0, [R1]
	
	LDR R0, [R1] ; Delay before we continue on

	; GPIO_PORTE_AMSEL_R = 0x00
	MOV R0, #0x00
	LDR R1, =GPIO_PORTE_AMSEL_R
	STR R0, [R1]
	
	; GPIO_PORTE_PCTL_R = 0x00
	MOV R0, #0x00
	LDR R1, =GPIO_PORTE_PCTL_R
	STR R0, [R1]
	
	; GPIO_PORTE_DIR_R = 0x01
	MOV R0, #0x01
	LDR R1, =GPIO_PORTE_DIR_R
	STR R0, [R1]
	
	; GPIO_PORTE_AFSEL_R = 0x00
	MOV R0, #0x00
	LDR R1, =GPIO_PORTE_AFSEL_R
	STR R0, [R1]
	
	; GPIO_PORTE_DEN_R = 0x03
	MOV R0, #0x03
	LDR R1, =GPIO_PORTE_DEN_R
	STR R0, [R1]
	
	; Start with the LED on
	MOV R0, #0x01
	LDR R1, =GPIO_PORTE_DATA_R
	STR R0, [R1]
	
main
	; Nothing needs to be initialized here
	; because it will run through all of InitPortF first

loop  
	BL delay62MS ; We want to delay at the beginning now
	;Read the switch and test if the switch is pressed
	LDR R1, =GPIO_PORTE_DATA_R ; Load the address of Port E data into R1 so we can use it
	LDR R0, [R1] ; Load the value at R1 (the port data) into R0
	LSR R0, #1 ; Shift the port data to the right 1 bits since we only need pin 1
	CMP R0, #1 ; Compare the value to 1
	BEQ toggleLED ; If the value at R0 is 1, we want to toggle the LED
	; If we didn't branch off on the previous instruction,
	; then all we want to do is turn on the LED and then
	; restart the loop
	MOV R0, #0x01 
	LDR R1, =GPIO_PORTE_DATA_R
	; This will move 0x01 into the Port E data register
	; which will turn on the LED
	STR R0, [R1]
	; go to the beginning of the loop
    B loop
	
toggleLED ; Toggles the LED
	; Read our current Port F data because
	; we need to check if the LED is on or not
	LDR R1, =GPIO_PORTE_DATA_R ; Load the address of the Port F data into R1 so we can use it
	LDR R0, [R1] ; Load the value at R1 (the port data) into R0
	; Pin 1 is always on when we call toggleLED
	CMP R0, #0x02 ; Check if the value in R0 is 10, which indicates pin 0 is off and pin 1 is on, hence the LED is off
	BEQ turnOnLED ; if this value is 10, then that means our LED is currently off and we need to turn it on
	; Otherwise, just turn off the LED
	MOV R0, #0x00
	LDR R1, =GPIO_PORTE_DATA_R
	; This will move 0x00 into the Port E data register
	; which will turn off the LED
	STR R0, [R1]
	; Then we need to delay by 62ms
	BL delay62MS
	; And begin our loop again
	B loop
	
turnOnLED ; Turns the LED on, no matter what state it is in currently
	MOV R0, #0x01
	LDR R1, =GPIO_PORTE_DATA_R
	STR R0, [R1]
	; Again, we need to delay 62ms
	BL delay62MS
	; and begin our loop again
	B loop

delay62MS ; Subroutine that will delay our code by roughly 62ms
	; To delay the running by about 62ms we need to put
	; a large number into a register and slowly reduce it
	; so that we take up 62ms worth of cycles
	; the large number we've chosen is #0xB5000
	MOV R7, #0x5000
	MOVT R7, #0xB
delay
	SUBS R7, R7, #0x01 ; Subtract the current value of R12 by 1 and put it into R12
	BNE delay ; Compare R12 to 0 and if it is not 0, go back to delay
	BX LR ; Go back to the line after the delay62MS was called
	
       ALIGN      ; make sure the end of this section is aligned
       END        ; end of file
       