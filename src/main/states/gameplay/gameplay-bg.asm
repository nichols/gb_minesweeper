INCLUDE "src/main/utils/hardware.inc"

SECTION "GameplayBG", ROM0

MineBgTileData: INCBIN "src/generated/backgrounds/mine-bg-tiles.2bpp"
MineBgTileDataEnd:

MineObjTileData: INCBIN "src/generated/sprites/mine-obj-tiles.2bpp"
MineObjTileDataEnd:

; Write *d *e times, starting at address hl
; input:
;   d is the byte to write
;   e is the number of consecutive addresses to write it to
;   hl is the first address to write it to
; destroys a
InitGridRowLoop:
    ld a, d
    ld [hli], a
    dec e
    ld a, e
    cp a, 0
    jp nz, InitGridRowLoop
    ret

; Add a row of blank tiles to the tilemap
; input:
;   hl is the address of the leftmost tile in a row
; destroys d, e
BlankRow:
    ld e, 32
    ld d, $80
    call InitGridRowLoop
    ret

; Add a row to the tilemap that includes a row of the mine grid
; input:
;   hl is the address of the leftmost tile in a row
; destroys d, e
InitGridRow:
    ld e, 16
    ld d, $8C
    call InitGridRowLoop

    ld e, 16
    ld d, $80
    call InitGridRowLoop
    ret


InitializeBackground::

    ; Copy the BG tile data
    ld de, MineBgTileData ; de contains the address where data will be copied from;
    ld hl, $8800 ; hl contains the address where data will be copied to;
    ld bc, MineBgTileDataEnd - MineBgTileData ; bc contains how many bytes we have to copy.
    call CopyDEintoMemoryAtHL

    ; Copy the object tile data
    ld de, MineObjTileData ; de contains the address where data will be copied from;
    ld hl, $8000 ; hl contains the address where data will be copied to;
    ld bc, MineObjTileDataEnd - MineObjTileData ; bc contains how many bytes we have to copy.
    call CopyDEintoMemoryAtHL

    ; Create initial tilemap
    ld hl, $9800
    ; 2 blank rows at top
    call BlankRow
    call BlankRow
    ; 16 grid rows
    ld c, 16
CreateGridRows:
    call InitGridRow
    dec c
    ld a, c
    cp a, 0
    jp nz, CreateGridRows
    ; 14 empty rows
    ld c, 14
CreateBlankRowsAfterGrid:
    call BlankRow
    dec c
    ld a, c
    cp a, 0
    jp nz, CreateBlankRowsAfterGrid

    ret



; input: a stores grid index (16*row index + column index)
;        destroys b, d, hl
; output: nothing
UpdateBgTile::
    ld b, a  ; save for later

    ; load the grid data byte for this space into d
    call GetGridDataAddressForGridIndex
    ld d, [hl]

    ; reload a which was destroyed
    ld a, b
    call GetTileAddressForGridIndex ; now hl is the tile address

    ; now check the grid data byte and update the tile to match its state
    ld a, d
    and %01100000
    jp z, SpaceIsUncovered
SpaceIsCovered:
    ; blank covered square, flag, or ?
    cp a, %01000000  ; is the space uncovered with a flag
    jp z, CoveredWithFlag
    cp a, %00100000  ; is the space uncovered with a ?
    jp z, CoveredWithQM
CoveredWithoutMark:
    ld [hl], $8C
    ret
CoveredWithFlag:
    ld [hl], $8D
    ret
CoveredWithQM:
    ld [hl], $8E
    ret
SpaceIsUncovered:
    ; bomb (game over), number, or empty space
    ld a, d
    bit 7, a  ; check most significant bit
    jp z, UncoveredSpaceNoBomb
UncoveredSpaceWithBomb:
    ld [hl], $8F
    ret
UncoveredSpaceNoBomb:
    ld a, d
    and %00001111  ; keep just adjacent bomb count
    add a, $81     ; address of blank zero tile
    ld [hl], a
    ret
    