;MMIO
PPUCTRL = $2000     ;changes the operation of PPU, bit 7 controls whether the PPU will trigger an NMI every frame
PPUMASK = $2001     ;storing $00 to PPUCTRL and MASK, you turn off NMIs and disable rendering to the screen during start up
PPUSTATUS = $2002   ;resets address latch on PPUADDR
PPUADDR = $2006     ;address is set first high(left) byte, then low(right) byte
PPUDATA = $2007     ;writes data to PPUADDR
OAMADDR = $2003     ;used to set where in OAM we want to write to; will always be $00, the beginning of the OAM block
OAMDMA = $4014      ;initiates the transfer of an entire page of memory into OAM; writing the hight byte of a memory addr to OAMDMA will transfer that page
;controllers
CONTROLLER1 = $4016
CONTROLLER2 = $4017

BTN_RIGHT   = %00000001
BTN_LEFT    = %00000010
BTN_DOWN    = %00000100
BTN_UP      = %00001000
BTN_START   = %00010000
BTN_SELECT  = %00100000
BTN_B       = %01000000
BTN_A       = %10000000