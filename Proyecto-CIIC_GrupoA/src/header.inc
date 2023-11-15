.segment "HEADER"
.byte $4e, $45, $53, $1a    ;"N", "E", "S", [end of file character]; identifies the file as an "iNES" game
.byte $02                   ;Number of 16kB PRG-ROM banks
.byte $02                   ;Number of 8kB CHR-ROM banks
.byte %00000001             ;Vertical mirroring, no save RAM, no mapper
.byte %00000000             ;No special-case flags set, no mapper
.byte $00                   ;No PRG-RAM present
.byte %00                   ;NTSC format