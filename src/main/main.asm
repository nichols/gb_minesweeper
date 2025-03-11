INCLUDE "src/main/utils/hardware.inc"

SECTION "GameVariables", WRAM0

wLastKeys:: db
wCurKeys:: db
wNewKeys:: db
wGameState::db

SECTION "Header", ROM0[$100]

	jp EntryPoint

	ds $150 - @, 0 ; Make room for the header

EntryPoint:
	; Shut down audio circuitry
	ld a, 0
	ld [rNR52], a

	; Initialize game state
	; We don't actually need another xor a here, because the value of A doesn't change between these two instructions
	ld [wGameState], a

	; Wait for the vertical blank phase before initiating the library
    call WaitForOneVBlank

	; TODO initialize sprite library?

	; Turn the LCD off
	xor a
	ld [rLCDC], a

	; TODO load any global graphics data

	; Turn the LCD on
	ld a, LCDCF_ON  | LCDCF_BGON|LCDCF_OBJON | LCDCF_OBJ16 | LCDCF_WINON | LCDCF_WIN9C00
	ld [rLCDC], a

	; During the first (blank) frame, initialize display registers
	ld a, %11100100
	ld [rBGP], a   ; BG palette
	ld [rOBP0], a  ; OBJ palette 0
	; ld [rOBP1], a  ; OBJ palette 1

	NextGameState::

		; Do not turn the LCD off outside of VBlank
		call WaitForOneVBlank
	
		; TODO Clear background
	
		; Turn the LCD off
		xor a
		ld [rLCDC], a
	
		ld [rSCX], a
		ld [rSCY], a
		ld [rWX], a
		ld [rWY], a
		
		; TODO Clear all sprites
	
		; Initiate the next state
		ld a, [wGameState]
		cp 1 ; 1 = Gameplay
		call z, InitGameplayState
		and a ; 0 = Title Screen
		call z, InitTitleScreenState
	
		; Update the next state
		ld a, [wGameState]
		cp 1; 1 = Gameplay
		jp z, UpdateGameplayState
		jp UpdateTitleScreenState

