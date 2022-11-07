MODE7
tstaddr = &8008
values = &90
unique = &80
RomSel = &FE30
RamSel = &FE32
UsrDat = &FE60
UsrDDR = &FE62
REM Find 16 values distinct from the 16 rom values and each other and save the original rom values
DIM CODE &100
FOR P = 0 TO 2 STEP 2
P%=CODE
[OPT P
SEI
LDY #15        \\ unique values (-1) to find
\\STY UsrDDR     \\ set user via DDRB low bits as output - required for Solidisk SW RAM
TYA            \\ A can start anywhere less than 256-64 as it just needs to allow for enough numbers not to clash with rom, tst and uninitialised tst values
.next_val
LDX #15        \\ sideways bank
ADC #1         \\ will inc mostly by 2, but doesn't matter
.next_slot
STX RomSel
CMP tstaddr
BEQ next_val
CMP unique,X   \\ doesn't matter that we haven't checked these yet as it just excludes unnecessary values, but is safe
BEQ next_val
DEX
BPL next_slot
STA unique,Y
LDX tstaddr
STX values,Y
DEY
BPL next_val
\\ Try to swap each rom value with a unique test value - top down wouldn't work for Solidisk
LDX #0         \\ count up to allow for Solidisk only having 3 select bits
.swap
\\STX UsrDat     \\ set Solidisk SWRAM index
STX RamSel     \\ set RamSel incase it is used
STX RomSel     \\ set RomSel as it will be needed to read, but is also sometimes used to select write
LDA unique,X
STA tstaddr
INX            \\ count up to allow for Solidisk only have 3 select bits
CPX #16
BNE swap
\\ count matching values and restore old values - reverse order to swapping is safe
LDY #16
LDX #15
.tst_restore
STX RomSel
LDA tstaddr
CMP unique,X   \\ if it has changed, but is not this value, it will be picked up in a later bank
BNE not_swr
\\STX UsrDat     \\ set Solidisk SWRAM index
STX RamSel     \\ set RamSel incase it is used
LDA values,X
STA tstaddr
DEY
STX values,Y
.not_swr
DEX
BPL tst_restore
STY values
LDA &F4
STA RomSel     \\ restore original ROM
CLI
RTS
.INIT1
LDA &F4:PHA
LDA &8F:STA &F4:STA &FE30 \\ RAM BANK IN &8F
JSR &8000
PLA:STA &F4:STA &FE30
RTS
.INIT2
LDA &F4:PHA
LDA &8F:STA &F4:STA &FE30 \\ RAM BANK IN &8F
JSR &8003
PLA:STA &F4:STA &FE30
RTS
.PLAY
LDA &F4:PHA
LDA &8F:STA &F4:STA &FE30 \\ RAM BANK IN &8F
JSR &8006
PLA:STA &F4:STA &FE30
RTS
]
NEXT
CALL CODE
N%=16-?&90
IF N%=0 THEN PRINT'"No SWRAM detected.":END
PRINT'"Detected ";16-?&90;" SWRAM banks:";
IF N% > 0 THEN FOR X% = ?&90 TO 15 : PRINT;" ";X%?&90; : NEXT
?&8F=?(&90+?&90):REM STORE RAM BANK USED SOMEWHERE IN ZERO PAGE
PRINT'"Loading music to SWRAM bank: ";?&8F
OSCLI "SRLOAD Music 8000 "+STR$(?&8F)
T%=1
REPEAT
PRINT'"Init tune: ";T%
IF T%=1 THEN CALL INIT1 ELSE CALL INIT2
PRINT "Playing... press any key for next tune"
REPEAT:REM WAIT FOR VSYNC OR CALL IN APPROPRIATE EVENT HANDLER
*FX19
CALL PLAY
UNTIL INKEY(0)<>-1
T%=T%+1:IF T%>2 THEN T%=1
UNTIL FALSE
