.include "constants.inc"

.segment "ZEROPAGE"
.importzp player_x, player_y, player_dir    ;import zp addresses

.segment "CODE"
.import main
.export reset_handler
.proc reset_handler   ;reset or start up
  SEI         ;after SEI, anything that would trigger an IRQ will be ignored
  CLD         ;Clear Decimal mode bit, disables binary coded decimal mode
  LDX #$00
  STX PPUCTRL   ;PPUCTRL changes the operation of PPU, bit 7 controls whether the PPU will trigger an NMI every frame
  STX PPUMASK   ;storing $00 to PPUCTRL and MASK, you turn off NMIs and disable rendering to the screen during start up

vblankwait:         ;this parts wait for the PPU to fully boot
  BIT PPUSTATUS
  BPL vblankwait
  
  ;hides all sprites off the screen until we explicitly set them ourselves to prevent visual bugs
  LDX #$00
  LDA #$ff
clear_oam:
  STA $0200,X   ;set sprite y-positions off the screen
  INX
  INX
  INX
  INX
  BNE clear_oam

vblankwait2:
  BIT PPUSTATUS
  BPL vblankwait2

  ;initialize zero-page values (player's x and y coordinates)
  LDA #$80
  STA player_x
  LDA #$a0
  STA player_y
  LDA #$01
  STA player_dir

  JMP main
.endproc