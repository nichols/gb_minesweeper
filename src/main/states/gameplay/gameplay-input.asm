INCLUDE "src/main/utils/hardware.inc"
INCLUDE "src/main/states/gameplay/constants.inc"

SECTION "GameplayInput", ROM0
	
HandleInput::

CheckLeft:
	ld a, [wNewKeys]
	and a, PADF_LEFT
	jp z, CheckRight
    call PressLeft
    jp DoneHandleInput

CheckRight:
	ld a, [wNewKeys]
	and a, PADF_RIGHT
	jp z, CheckUp
    call PressRight
    jp DoneHandleInput

CheckUp:
    ld a, [wNewKeys]
    and a, PADF_UP
    jp z, CheckDown
    call PressUp
    jp DoneHandleInput

CheckDown:
    ld a, [wNewKeys]
    and a, PADF_DOWN
    jp z, CheckA
    call PressDown
    jp DoneHandleInput

CheckA:
    ld a, [wNewKeys]
    and a, PADF_A
    jp z, CheckB
    call PressA
    jp DoneHandleInput

CheckB:
    ld a, [wNewKeys]
    and a, PADF_B
    jp z, DoneHandleInput
    call PressB

DoneHandleInput:
    ret


PressLeft:
    ; Move the cursor one tile to the left.
    ld a, [_OAMRAM + 1]
    sub a, 8
    ; If we've already hit the edge of the playfield, don't move.
    cp a, 0
    ret z
    ld [_OAMRAM + 1], a
    ld a, [wCursorCol]
    dec a
    ld [wCursorCol], a
    ret

PressRight:
    ; Move the cursor one tile to the right.
    ld a, [_OAMRAM + 1]
    add a, 8
    ; If we've already hit the edge of the playfield, don't move.
    cp a, 8 + 8 * 16
    ret z
    ld [_OAMRAM + 1], a
    ld a, [wCursorCol]
    inc a
    ld [wCursorCol], a
    ret

PressUp:
    ; Move the cursor one tile up
    ld a, [_OAMRAM]
    sub a, 8
    ; check edge of playfield
    cp a, 8 + 16
    ret z
    ld [_OAMRAM], a
    ld a, [wCursorRow]
    dec a
    ld [wCursorRow], a
    ret

PressDown:
    ; Move the cursor one tile down
    ld a, [_OAMRAM]
    add a, 8
    ; check edge of playfield
    cp a, 16 + 8 * 2 + 8 * 16
    ret z
    ld [_OAMRAM], a
    ld a, [wCursorRow]
    inc a
    ld [wCursorRow], a
    ret

PressA:
    call GetGridIndex  ; store grid index in register a
    ld b, a  ; store for later
    ld hl, wGridData
    ld l, a  ; this works because wGridData is aligned
    ; now hl stores the address of the grid data byte
    ld a, [hl]
    and MASK_CLEAR_COVERED_SQUARE_AND  ; set state to uncovered
    ld [hl], a
    ld a, b
    call UpdateBgTile
    ret


PressB:
    ld a, [wCursorRow]
    swap a ; move cursor row index into the most significant 4 bits of a
    ld hl, wCursorCol
    or a, [hl]
    ld b, a  ; store for later
    ld hl, wGridData
    ld l, a  ; this works because wGridData is aligned
    ; now hl stores the address of the grid data byte
    ld a, [hl]
    and %01100000  ;  discard all bits except the ones that control cover/flags

CheckCoveredBlank:
    cp a, %01100000  ; covered with no flag
    jp nz, CheckCoveredFlag
    ld a, [hl]
    and %11011111  ; unset 3rd bit to turn covered blank into covered flag
    ld [hl], a
    jp CheckCoveredStatusDone

CheckCoveredFlag:
    cp a, %01000000  ; covered with flag
    jp nz, CheckCoveredQM
    ld a, [hl]
    ; unset 6th bit and set 5th bit to turn covered flag into covered QM
    res 6, a
    set 5, a
    ld [hl], a
    jp CheckCoveredStatusDone

CheckCoveredQM:
    cp a, %00100000  ; covered with ?
    jp nz, CheckUncovered
    ld a, [hl]
    or %01000000  ; set 2nd bit to turn covered QM into covered blank
    ld [hl], a
    jp CheckCoveredStatusDone

CheckUncovered:
    cp a, %00000000  ; uncovered; do nothing

CheckCoveredStatusDone:
    ld a, b
    call UpdateBgTile
    ret

