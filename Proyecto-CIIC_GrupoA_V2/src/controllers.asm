;file for controller-related subroutines
.include "constants.inc"

.segment "ZEROPAGE"
.importzp pad1

.segment "CODE"
.export read_controller1
.proc read_controller1
    PHA
    TXA
    PHA
    PHP

    ;write a 1, then a 0 to bit 0 of CONTROLLER1; to latch button states
    LDA #$01
    STA CONTROLLER1
    LDA #$00
    STA CONTROLLER1

    ;initial state of pad1
    LDA #%00000001      ;each time we read a button state, we shift and rotate left it into pad1
    STA pad1            ;when that 1 rotates into the carry flag, we have transfered eight button states and can end the loop

get_buttons:
    LDA CONTROLLER1     ;read the next button's state
    LSR A               ;shift button state right, into carry flag
    ROL pad1            ;rotate button state from carry flag onto right side of pad1; and leftmost bit into carry flag
    BCC get_buttons     ;continue until carry flag set (original 1 rotated all the way left into carry flag)
    ;at this point we read and stored all the contoller's button states

    ;set BTN_DOWN to 1 always
    ;LDA pad1
    ;ORA #%00000100
    ;STA pad1
    

    PLP
    PLA
    TAX
    PLA
    RTS
.endproc
