INCLUDE "src/main/utils/hardware.inc"

SECTION "GameplayVariables", WRAM0, ALIGN[8]
; align to make sure that wGridData is aligned
; this makes things much easier because in the address of any grid square's
; data, the 4 least significant bits are the column index and the next 4
; bits are the row index 

; We'll store the following for each grid square:
;   no bomb or bomb (1 bit) (most significant)
;   covered, flag, ?, uncovered (2 bits)
;   Number of adjacent bombs (4 bits) (least significant)
; This is one byte per grid square, or 256 bytes
; GB has about 8K bytes of WRAM so this should be okay
; Note that storing the adjacent bomb count in the least significant bits lets
; us increment it by incrementing the entire byte. We don't have to worry about
; overflow because the adjacent bomb count can never be greater than 8.
wGridData:: ds 256

; Current column and row indices of the cursor
wCursorCol:: db
wCursorRow:: db

; Total bombs on the field
wTotalBombs:: db
; Bombs minus flags. Also used to keep track of current count when adding bombs during grid initialization.
wRemainingBombs:: db

SECTION "GameplayState", ROM0


InitializeCursor:

	; Initialize OAM
    ld a, 0
    ld b, 160
    ld hl, _OAMRAM
ClearOam:
    ld [hli], a
    dec b
    jp nz, ClearOam

    ; Initialize the cursor sprite in OAM
    ld hl, _OAMRAM
    ld a, 16 + 16  ; y coordinate (plus offset 16)
    ld [hli], a
    ld a, 0 + 8    ; x coordinate (plus offset 8)
    ld [hli], a
    ld a, 16		; tile ID
    ld [hli], a
    ld [hli], a		; attributes (none)

    ret



InitGameplayState::

    ld a, 40
    ld [wTotalBombs], a
    ld a, 0
    ld [wRemainingBombs], a
	ld a, 0
	ld [wCursorCol], a
	ld [wCursorRow], a

    call InitEmptyGrid
    call AddBombs

	call InitializeBackground
	call InitializeCursor

    ; Setup display
	ld a, 0
	ld [rWY], a
	ld a, 7
	ld [rWX], a
	; Turn the LCD on
	ld a, LCDCF_ON  | LCDCF_BGON|LCDCF_OBJON
	ld [rLCDC], a

    ret
	
UpdateGameplayState::

	; save the keys last frame
	ld a, [wCurKeys]
	ld [wLastKeys], a

	; This is in input.asm
	; It's straight from: https://gbdev.io/gb-asm-tutorial/part2/input.html
	; In their words (paraphrased): reading player input for gameboy is NOT a trivial task
	; So it's best to use some tested code
    call Input

    call HandleInput  ; one big function that updates everything. not good.

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; Call our function that performs the code
    call WaitForOneVBlank
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; Aren't objects/OAMRAM supposed to be updated during vblank?

	jp UpdateGameplayState

EndGameplay::

    ld a, 0  ; title screen
    ld [wGameState],a
    jp NextGameState



