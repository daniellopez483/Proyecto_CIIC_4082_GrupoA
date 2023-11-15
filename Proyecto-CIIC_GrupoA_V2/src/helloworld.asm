.include "constants.inc"
.include "header.inc"

;aqui va la reserva de memoria de zero-page ($0000-$00ff)(256 addresses)
.segment "ZEROPAGE"
player_x: .res 1      ;memory range we want to reserve (1 byte)
player_y: .res 1      ;(for player x and y position)(top left coord of the top left tile)
player_dir: .res 1    ;player direction; 0 = moving left; 1 = moving right; 2 = moving up
pad1: .res 1          ;a byte to store our controller data
pointerLo: .res 1 ;One-byte low memory address variable
pointerHi: .res 1 ;One-byte high memory address variable
.exportzp player_x, player_y, player_dir, pad1    ;export their definition from reset.asm

.segment "CODE"
.proc irq_handler   ;Interrupt Request
  RTI               ;Return form Interrupt
.endproc

.import read_controller1    ;import read_controller1 from controllers.asm

.proc nmi_handler   ;Non-Maskable Interrupt happens when PPU starts preparing the next frame of graphics, 60 times per second
  LDA #$00
  STA OAMADDR       ;tells the PPU to prepare for a transfer to OAM starting at byte zero
  LDA #$02
  STA OAMDMA        ;tells the PPU to initiate a transfer of the 256 bytes from $0200-$02ff into OAM
  
  ;read controller
  JSR read_controller1
  
  ;update tiles after DMA transfer
  JSR update_player
  JSR draw_player

  LDA #$00          ;set scroll position of the nametables to display the forst nametable, with no scrolling
  STA $2005
  STA $2005
  RTI
.endproc            ;keeps OAM updated after every frame

.import reset_handler
.export main

.proc main
  ;write a palette
  LDX PPUSTATUS       ;PPUSTATUS resets address latch on PPUADDR
  LDX #$3f
  STX PPUADDR         ;PPUADDR high(left) byte (for palette address)
  LDX #$00
  STX PPUADDR         ;PPUADDR low(right) byte

load_palettes:
  LDA palettes,X      ;X is already set to 0
  STA PPUDATA
  INX
  CPX #$20            ;0 to 32; $3f00 to 3f20 loads all eight palettes
  BNE load_palettes

  LDA PPUSTATUS
	LDA #$23
	STA PPUADDR
	LDA #$e0
	STA PPUADDR
	LDA #%00001100
	STA PPUDATA       ;write palette data to PPU memory $23e0

  ;attribute table
  LDA PPUSTATUS
  LDA #$23
  STA PPUADDR
  LDA #$c2
  STA PPUADDR
  LDA #%01000000    ;sets the palette for the bottom-right section (secon 01 in this example) and the rest, the first one (00)
  STA PPUDATA       ;write the palette data to PPU mem $23c2

LoadBackground:
  LDA PPUSTATUS ; Load the current status of the PPU into the accumulator
  LDA #$20 ; Load the constant value $20 into the accumulator
  STA PPUADDR ; Store the accumulator content into the PPU address register, setting the high byte of the address
  LDA #$00 ; Load the constant value $00 into the accumulator
  STA PPUADDR ; Store the accumulator content into the PPU address register again, setting the low byte of the address

  
  LDA #<background ; Load the low byte of the memory address of 'background' into the accumulator
  STA pointerLo ; Store the accumulator content into the low byte of 'pointerLo'
  LDA #>background ; Load the high byte of the memory address of 'background' into the accumulator
  STA pointerHi ; Store the accumulator content into the high byte of 'pointerHi'


  LDY #$00  ;Sets Y to 0
  LDX #$00  ;Sets X to 0
  
LoadBackgroundLoop: ; Start of the double loop (X and Y)
  LDA (pointerLo), y ; Load the byte from memory addressed by (pointerLo + Y) into the accumulator
  STA $2007 ; Store the accumulator content into PPU address $2007, sending it to the PPU
  INY ; Increment Y register
  CPY #$00 ; Compare Y register with zero

  BNE LoadBackgroundLoop ; If Y is not zero, branch back to InsideLoop

  INC pointerHi ; Increment the high byte of the pointer
  INX ; Increment X register
  CPX #$04 ; Compare X register with 4

  BNE LoadBackgroundLoop ; If X is not 4, branch back to InsideLoop


vblankwait:   ;wait for another vblank before continuing
  BIT PPUSTATUS
  BPL vblankwait

  LDA #%10010000    ;turn on NMIs, sprites use first pattern table
  STA PPUCTRL
  LDA #%00011110    ;turn on screen
  STA PPUMASK

forever:
  JMP forever
.endproc

.proc update_player ;;;;;;;;;;;need to implement "gravity" with this;;;;;;;;;;;;;;;;;;;
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;updated para incluir input;;;;;;;;;;;;;;;;;;;;;;;;;
  LDA pad1        ;load button presses
  AND #BTN_LEFT   ;filter out all but left
  BEQ check_right   ;if result is zero, left is not pressed
  ;update direction
  LDA #$00
  STA player_dir
  ;check left bound
  LDA player_x
  CMP #$10
  BCC check_right
  DEC player_x    ;if the branch is not taken, move player left
check_right:
  LDA pad1
  AND #BTN_RIGHT
  BEQ check_up
  ;update direction
  LDA #$01
  STA player_dir
  ;check right bound
  LDA player_x
  CMP #$e0
  BCS check_up
  INC player_x
check_up:
  LDA pad1
  AND #BTN_UP
  BEQ check_down
  ;update direction
  LDA #$02
  STA player_dir
  ;check upper bound
  LDA player_y
  CMP #$10
  BCC check_down
  DEC player_y
check_down:
  LDA pad1
  AND #BTN_DOWN
  BEQ done_checking
  ;check lower bound
  LDA player_y
  CMP #$d7            ;e0 minus 09 so lower half of the sprite does not get hidden
  BCS done_checking
  INC player_y
done_checking:
  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS
.endproc

.proc draw_player
  ;save registers
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  ;write player tile numbers
  ;if facing right
  LDA player_dir
  CMP #02
  BEQ facing_up
  CMP #$01
  BNE facing_left
  LDA #$10    ;tile number (top left part)
  STA $0201   ;memory address (they correspont to "byte 2" of the first four sprites)
  LDA #$11    ;tile number (top right)
  STA $0205
  LDA #$12    ;tile (bottom left)
  STA $0209
  LDA #$13    ;tile (bottom right)
  STA $020d
  JMP finished_tiles

;if facing left
facing_left:
  LDA #$11    ;tile number (top left part)
  STA $0201   ;memory address (they correspont to "byte 2" of the first four sprites)
  LDA #$10    ;tile number (top right)
  STA $0205
  LDA #$13    ;tile (bottom left)
  STA $0209
  LDA #$12    ;tile (bottom right)
  STA $020d
  JMP finished_tiles

  ;if facing up
facing_up:
  LDA #$09    ;tile number (top left part)
  STA $0201   ;memory address (they correspont to "byte 2" of the first four sprites)
  LDA #$0A    ;tile number (top right)
  STA $0205
  LDA #$12    ;tile (bottom left)
  STA $0209
  LDA #$13    ;tile (bottom right)
  STA $020d

  LDA #$00
  STA $0202     ;memories immediately after the previous tile addresses so they
  STA $0206     ;hold the attributes of the first four sprites (A = $00)
  STA $020a
  STA $020e     ;in order: top left, top right, bottom left, bottom right
  JMP finished_flip
finished_tiles:

  ;write player attributes
  ;;;;;;;;;;;;;;;;ejemplo con palette 0;;;;;;;;;;;;
  ;if not flipped
  LDA player_dir
  CMP #$01
  BNE if_flipped
  LDA #$00      ;palette number and attributes
  STA $0202     ;memories immediately after the previous tile addresses so they
  STA $0206     ;hold the attributes of the first four sprites (A = $00)
  STA $020a
  STA $020e     ;in order: top left, top right, bottom left, bottom right
  JMP finished_flip

if_flipped:
  LDA #$40      ;palette number and attributes
  STA $0202     ;memories immediately after the previous tile addresses so they
  STA $0206     ;hold the attributes of the first four sprites (A = $00)
  STA $020a
  STA $020e     ;in order: top left, top right, bottom left, bottom right
finished_flip:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;store tile locations
  ;top left tile:
  LDA player_y
  STA $0200       ;save Y-coord to memory
  LDA player_x
  STA $0203       ;save X-coord to memory

  ;top right tile: (x + 8)
  LDA player_y
  STA $0204
  LDA player_x
  CLC             ;clear carry
  ADC #$08
  STA $0207

  ;bottom left tile: (y + 8)
  LDA player_y
  CLC
  ADC #$08
  STA $0208
  LDA player_x
  STA $020b

  ;bottom right tile: (y + 8, x + 8)
  LDA player_y
  CLC
  ADC #$08
  STA $020c
  LDA player_x
  CLC
  ADC #$08
  STA $020f

  ;restore registers and return
  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS
.endproc

.segment "RODATA"
palettes:                   ;palette's four colors
.byte $21, $26, $15, $30    ;background palettes
.byte $21, $0f, $2c, $30
.byte $21, $16, $0f, $26
.byte $21, $0f, $19, $29

.byte $21, $16, $28, $1B    ;sprite palettes
.byte $21, $19, $09, $29
.byte $21, $19, $09, $29
.byte $21, $19, $09, $29

background:
.incbin "src/background.nam" ;Load background nametable

.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

.segment "CHR"
.incbin "mario.chr"