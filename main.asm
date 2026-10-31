;
; bartek8879_git.asm
;
; Created: 31.10.2026 17:45:51
; Author : Ziuuuuum
;

.include "m32def.inc"


;===============================================================
; INTERRUPT VECTOR TABLE
;===============================================================

.cseg

.org 0x000
    jmp start

.org 0x002
    jmp default_isr

.org 0x004
    jmp default_isr

.org 0x006
    jmp default_isr

.org 0x008
    jmp default_isr

.org 0x00A
    jmp default_isr

.org 0x00C
    jmp default_isr

.org 0x00E
    jmp default_isr

.org 0x010
    jmp default_isr

.org 0x012
    jmp timer1_ovf

.org 0x014
    jmp default_isr

.org 0x016
    jmp default_isr

.org 0x018
    jmp default_isr

.org 0x01A
    jmp default_isr

.org 0x01C
    jmp default_isr

.org 0x01E
    jmp default_isr

.org 0x020
    jmp default_isr

.org 0x022
    jmp default_isr

.org 0x024
    jmp default_isr

.org 0x026
    jmp default_isr

.org 0x028
    jmp default_isr



;===============================================================
; MAIN PROGRAM
;===============================================================

.org 0x100


default_isr:

    reti



start:

    cli


    ;-----------------------------------------------------------
    ; STACK
    ;-----------------------------------------------------------

    ldi r16, high(RAMEND)
    out SPH, r16

    ldi r16, low(RAMEND)
    out SPL, r16


    ;-----------------------------------------------------------
    ; INPUTS - PB0, PB1
    ;-----------------------------------------------------------

    cbi DDRB, PB0
    cbi DDRB, PB1


    ;-----------------------------------------------------------
    ; OUTPUTS - PD2-PD7, PC6-PC7
    ;-----------------------------------------------------------

    ldi r16, 0b11111100
    out DDRD, r16

    ldi r16, 0b11000000
    out DDRC, r16


    ; Turn off LEDs

    in   r16, PORTD
    andi r16, 0b00000011
    out  PORTD, r16

    in   r16, PORTC
    andi r16, 0b00111111
    out  PORTC, r16


    ;-----------------------------------------------------------
    ; STATE REGISTERS
    ;
    ; r17 - current LED mask
    ; r18 - active mode:
    ;       0 = stopped
    ;       1 = PB0 direction
    ;       2 = PB1 direction
    ; r19 - current port section
    ;-----------------------------------------------------------

    ldi r17, 0
    ldi r18, 0
    ldi r19, 0


    ;-----------------------------------------------------------
    ; TIMER1
    ; Normal mode, prescaler /64
    ;-----------------------------------------------------------

    ldi r16, 0
    out TCCR1A, r16

    ldi r16, (1<<CS11) | (1<<CS10)
    out TCCR1B, r16


    ; Timer preload for approximately 100 ms
    ; 0x9E58 = 40536
    ; 65536 - 40536 = 25000 counts

    ldi r16, 0x9E
    out TCNT1H, r16

    ldi r16, 0x58
    out TCNT1L, r16


    ; Enable Timer1 overflow interrupt

    in   r16, TIMSK
    ori  r16, (1<<TOIE1)
    out  TIMSK, r16


    sei



;===============================================================
; BUTTON CHECK
;===============================================================

check_buttons:

    in   r16, PINB
    andi r16, 0b00000001
    cpi  r16, 0
    brne check_pb1

    rjmp pb0_pressed



check_pb1:

    in   r16, PINB
    andi r16, 0b00000010
    cpi  r16, 0
    brne no_button_pressed

    rjmp pb1_pressed



;===============================================================
; NO BUTTON PRESSED
;===============================================================

no_button_pressed:

    cpi  r18, 0
    brne stop_effect

    rjmp check_buttons



;===============================================================
; STOP EFFECT
;===============================================================

stop_effect:

    cli

    ldi r18, 0
    ldi r19, 0
    ldi r17, 0


    ; Turn off PD2-PD7

    in   r16, PORTD
    andi r16, 0b00000011
    out  PORTD, r16


    ; Turn off PC6-PC7

    in   r16, PORTC
    andi r16, 0b00111111
    out  PORTC, r16


    ; Restart timer period

    ldi r16, 0x9E
    out TCNT1H, r16

    ldi r16, 0x58
    out TCNT1L, r16


    sei

    rjmp check_buttons



;===============================================================
; PB0
;===============================================================

pb0_pressed:

    ; Do not restart the effect if PB0 mode is already active

    cpi  r18, 1
    brne start_pb0_effect

    rjmp check_buttons



start_pb0_effect:

    cli

    ldi r18, 1
    ldi r19, 0          ; starting from PORTD
    ldi r17, (1<<PD2)


    ; Turn off PC6-PC7

    in   r16, PORTC
    andi r16, 0b00111111
    out  PORTC, r16


    ; Turn on PD2

    in   r16, PORTD
    andi r16, 0b00000011
    or   r16, r17
    out  PORTD, r16


    ; Next interrupt after approximately 100 ms

    ldi r16, 0x9E
    out TCNT1H, r16

    ldi r16, 0x58
    out TCNT1L, r16


    sei

    rjmp check_buttons



;===============================================================
; PB1
;===============================================================

pb1_pressed:

    ; Do not restart the effect if PB1 mode is already active

    cpi  r18, 2
    brne start_pb1_effect

    rjmp check_buttons



start_pb1_effect:

    cli

    ldi r18, 2
    ldi r19, 0          ; starting from PORTC
    ldi r17, (1<<PC7)


    ; Turn off PD2-PD7

    in   r16, PORTD
    andi r16, 0b00000011
    out  PORTD, r16


    ; Turn on PC7

    in   r16, PORTC
    andi r16, 0b00111111
    or   r16, r17
    out  PORTC, r16


    ; Next interrupt after approximately 100 ms

    ldi r16, 0x9E
    out TCNT1H, r16

    ldi r16, 0x58
    out TCNT1L, r16


    sei

    rjmp check_buttons



;===============================================================
; TIMER1 OVERFLOW INTERRUPT
;===============================================================

timer1_ovf:

    push r16

    in   r16, SREG
    push r16

    push r20


    ; Reload Timer1 for approximately 100 ms

    ldi r16, 0x9E
    out TCNT1H, r16

    ldi r16, 0x58
    out TCNT1L, r16


    ; Select active effect

    cpi  r18, 1
    brne check_pb1_mode

    rjmp timer_pb0



check_pb1_mode:

    cpi  r18, 2
    breq pb1_mode_selected

    rjmp timer_end



pb1_mode_selected:

    rjmp timer_pb1



;===============================================================
; TIMER - PB0
;
; PD2 -> PD3 -> PD4 -> PD5 -> PD6 -> PD7 -> PC6 -> PC7
;===============================================================

timer_pb0:

    ; r19 = 0 -> PORTD
    ; r19 = 1 -> PORTC

    cpi  r19, 0
    brne timer_pb0_portc


    ;-----------------------------------------------------------
    ; PB0 - PORTD
    ;-----------------------------------------------------------

    cpi  r17, (1<<PD7)
    breq pb0_switch_to_portc


    ; Move to next LED

    lsl r17


    in   r20, PORTD
    andi r20, 0b00000011
    or   r20, r17
    out  PORTD, r20

    rjmp timer_end



pb0_switch_to_portc:

    ; Turn off PD2-PD7

    in   r20, PORTD
    andi r20, 0b00000011
    out  PORTD, r20


    ; Switch to PORTC

    ldi r19, 1
    ldi r17, (1<<PC6)


    ; Turn on PC6

    in   r20, PORTC
    andi r20, 0b00111111
    or   r20, r17
    out  PORTC, r20

    rjmp timer_end



timer_pb0_portc:

    ; If PC7 is active, restart from PD2

    cpi  r17, (1<<PC7)
    breq pb0_restart


    ; PC6 -> PC7

    lsl r17


    in   r20, PORTC
    andi r20, 0b00111111
    or   r20, r17
    out  PORTC, r20

    rjmp timer_end



pb0_restart:

    ; Turn off PC6-PC7

    in   r20, PORTC
    andi r20, 0b00111111
    out  PORTC, r20


    ; Restart from PD2

    ldi r19, 0
    ldi r17, (1<<PD2)


    in   r20, PORTD
    andi r20, 0b00000011
    or   r20, r17
    out  PORTD, r20

    rjmp timer_end



;===============================================================
; TIMER - PB1
;
; PC7 -> PC6 -> PD7 -> PD6 -> PD5 -> PD4 -> PD3 -> PD2
;===============================================================

timer_pb1:

    ; r19 = 0 -> PORTC
    ; r19 = 1 -> PORTD

    cpi  r19, 0
    brne timer_pb1_portd


    ;-----------------------------------------------------------
    ; PB1 - PORTC
    ;-----------------------------------------------------------

    cpi  r17, (1<<PC6)
    breq pb1_switch_to_portd


    ; PC7 -> PC6

    lsr r17


    in   r20, PORTC
    andi r20, 0b00111111
    or   r20, r17
    out  PORTC, r20

    rjmp timer_end



pb1_switch_to_portd:

    ; Turn off PC6-PC7

    in   r20, PORTC
    andi r20, 0b00111111
    out  PORTC, r20


    ; Switch to PORTD

    ldi r19, 1
    ldi r17, (1<<PD7)


    ; Turn on PD7

    in   r20, PORTD
    andi r20, 0b00000011
    or   r20, r17
    out  PORTD, r20

    rjmp timer_end



timer_pb1_portd:

    ; If PD2 is active, restart from PC7

    cpi  r17, (1<<PD2)
    breq pb1_restart


    ; PD7 -> PD6 -> ... -> PD2

    lsr r17


    in   r20, PORTD
    andi r20, 0b00000011
    or   r20, r17
    out  PORTD, r20

    rjmp timer_end



pb1_restart:

    ; Turn off PD2-PD7

    in   r20, PORTD
    andi r20, 0b00000011
    out  PORTD, r20


    ; Restart from PC7

    ldi r19, 0
    ldi r17, (1<<PC7)


    in   r20, PORTC
    andi r20, 0b00111111
    or   r20, r17
    out  PORTC, r20



;===============================================================
; END OF TIMER INTERRUPT
;===============================================================

timer_end:

    pop r20

    pop r16
    out SREG, r16

    pop r16

    reti