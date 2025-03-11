INCLUDE "src/main/utils/hardware.inc"
INCLUDE "src/main/states/gameplay/constants.inc"

SECTION "GameplayMineGrid", ROM0

; input:
  ; hl is the address in wGridData of a space's grid data
  ; e is the offset within wGridData of an adjacent space's data
  ; destroys a
IncBombCountAtOffsetFromGridSpace:
    ld a, l
    add e
    ld l, a
    ld a, [hl]
    add 1
    ld [hl], a
    ld a, l
    sub e
    ld l, a

    ret

; input
;   a = grid index of the space in which a bomb is being placed
;   (so wGridData + a is the address of the grid data for this space)
;   destroys bc, e
IncrementAdjacentBombCounts:

    ;     a-17  a-16  a-15
    ;     a-1   a     a+1
    ;     a+15  a+16  a+17
    ;
    ; spots below/above are adjacent unless adding/subtracting 16 carries
    ; other spots may not be adjacent even if adding the offset doesn't carry

    ; Use one bit to track each neighbor in this order:
    ; UL, U, UR, R, DR, D, DL, L
    ld b, $FF
    ld c, a  ; store copy of a so we can keep destroying it

IncBombCountCheckTop: ; top row -> turn off the three neighbors above
    sub a, 16
    jp nc, IncBombCountCheckBottom
    ld a, b
    and %00011111
    ld b, a

IncBombCountCheckBottom: ; bottom row -> turn off the three neighbors below
    ld a, c
    sub a, 240
    jp c, IncBombCountCheckLeft
    ld a, b
    and %11110001
    ld b, a

IncBombCountCheckLeft: ; leftmost column -> turn off the three neighbors to the left
    ld a, c
    and %00001111  ; is a a multiple of 16?
    jp nz, IncBombCountCheckRight
    ld a, b
    and %01111100
    ld b, a

IncBombCountCheckRight: ; rightmost column -> turn off the three neighbors to the right
    ld a, c
    add 1
    and %00001111  ; is a+1 a multiple of 16?
    jp nz, ApplyIncrements
    ld a, b
    and %11000111
    ld b, a

ApplyIncrements:
    ld hl, wGridData
    ld d, b  ; store the bitmask
    ld b, 0  ; now bc = grid index
    add hl, bc  ; now hl is the address of the grid data of the new bomb space

ApplyL:
    bit 0, d
    jp z, ApplyDL
    ld e, 255  ; 256 - 1
    call IncBombCountAtOffsetFromGridSpace
ApplyDL:
    bit 1, d
    jp z, ApplyD
    ld e, 15
    call IncBombCountAtOffsetFromGridSpace
ApplyD:
    bit 2, d
    jp z, ApplyDR
    ld e, 16
    call IncBombCountAtOffsetFromGridSpace
ApplyDR:
    bit 3, d
    jp z, ApplyR
    ld e, 17
    call IncBombCountAtOffsetFromGridSpace
ApplyR:
    bit 4, d
    jp z, ApplyUR
    ld e, 1
    call IncBombCountAtOffsetFromGridSpace
ApplyUR:
    bit 5, d
    jp z, ApplyU
    ld e, 241  ; 256 - 15
    call IncBombCountAtOffsetFromGridSpace
ApplyU:
    bit 6, d
    jp z, ApplyUL
    ld e, 240  ; 256 - 16
    call IncBombCountAtOffsetFromGridSpace
ApplyUL:
    bit 7, d
    jp z, FinishIncrementAdjacentBombCounts
    ld e, 239  ; 256 - 17
    call IncBombCountAtOffsetFromGridSpace

FinishIncrementAdjacentBombCounts:

    ret


; destroys a, bc, e, hl
AddBombs::
AddBombsLoop:
    call RandLFSR
    ; a is now a random 8-bit number
    ; first four bits and second four bits are the row index (y) and column index (x) respectively
    ; since wGridData is aligned to have its lowest 8 bits all 0,
    ; we can just write a to these bits to get the address
    ld hl, wGridData
    ld l, a
    ld b, a  ; save the grid index of the new bomb
    ld a, [hl]

    ; see if there's already a bomb here and skip if so
    and MASK_HAS_MINE
    jp nz, AddBombsLoop

    ; add a bomb in this space
    ld a, [hl]
    or MASK_SET_MINE_OR
    ld [hl], a

    ; update bomb counts for the (up to) 8 adjacent squares
    ld a, b  ; get the grid index we saved earlier
    call IncrementAdjacentBombCounts

    ld a, [wTotalBombs]
    ld b, a
    ; update total bomb count
    ld a, [wRemainingBombs]
    inc a
    ld [wRemainingBombs], a
    ; if the bomb count is still below what we want, keep going
    cp b
    jp nz, AddBombsLoop

    ret


; Populate wGridData array with a completely blank mine grid.
; inputs: none
; destroys a, bc, hl
InitEmptyGrid::
    ld hl, wGridData
    ld bc, 256
InitGridLoop:
    ld [hl], MASK_CREATE_COVERED_SQUARE_NO_BOMBS  ; no bomb, no adjacent bombs, two bits turned on to indicate this is covered with no flag or ?.
    inc hl
    dec bc
    ld a, b
    or c
    jp nz, InitGridLoop


; input: a is a grid index
; output: hl is the address of the corresponding grid data byte
; destroys a
GetGridDataAddressForGridIndex::
    ; load the grid data byte for this space into d
    ld hl, wGridData
    add a, l
    ld l, a
    ret

; Convert an index in a 16x16 grid to a tilemap address
; given that the grid starts at (0,16) in real screen coords
; and each square is an 8x8 tile
;
; For instance index $23 (row 3, column 4) corresponds to tile address
; 9800 + (32 * (2 + 2)) + 3
; 9864 + (32 * ri) + ci
;
; This is more complicated than the above because we can't just add
; the grid index to the address of the start of the grid
;
; input: a is an index in the grid
; output: hl is the address of the corresponding tile
; destroys: b, c
GetTileAddressForGridIndex::
    push af ; store for later
    ld hl, $9840
    ; div by 16 to get row index, then multiply by 32
    and %11110000
    sla a
    ; if carry, we are in the bottom half of the grid.
    ; add an additional 256 offset
    jp nc, AddMainOffset
    ld bc, 256
    add hl, bc
AddMainOffset:
    ld c, a
    ld b, 0
    add hl, bc
    ; now get the column index
    pop af  ; restore saved a from the beginning
    and %00001111  ; discard 4 highest bits to get column index
    ld c, a
    ; b is still 0
    add hl, bc
    ret

; Based on RAM vars wCursorRow, wCursorCol, calculate grid index (0-255)
; output: a is the grid index
; destroys hl
GetGridIndex::
    ld a, [wCursorRow]
    swap a ; move cursor row index into the most significant 4 bits of a
    ld hl, wCursorCol
    or a, [hl]
    ret
