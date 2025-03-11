SECTION "MemoryUtilsSection", ROM0

; de points to the first byte to be copied
; hl points to the first destination address
; bc stores the number of bytes to be copied
CopyDEintoMemoryAtHL::
	ld a, [de]
	ld [hli], a
	inc de
	dec bc
	ld a, b
	or c
	jp nz, CopyDEintoMemoryAtHL ; Jump to CopyTiles if the last operation had a non zero result.
	ret

CopyDEintoMemoryAtHL_With52Offset::
	ld a, [de]
    add a, 52 
	ld [hli], a
	inc de
	dec bc
	ld a, b
	or c
	jp nz, CopyDEintoMemoryAtHL_With52Offset ; Jump to COpyTiles, if the z flag is not set. (the last operation had a non zero result)
	ret
