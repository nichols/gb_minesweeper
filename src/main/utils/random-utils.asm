
SECTION "RandVariables", WRAM0, ALIGN[3]
; Align this because it'll probably help us optimize the rand function later.

wRandSeed:: ds 8  ; 8 byte seed

SECTION "RandFunctions", ROM0

;------LFSR------
;James Montelongo
;optimized by Spencer Putt
;out:
; a = 8 bit random number
RandLFSR::
    ld hl, wRandSeed+4
    ld a, [hli]
    ld e, a
    ld a, [hli]
    ld d, a
    ld a, [hli]
    ld c, a
    ld a, [hl]
    ; now e,d,c,a hold the last 4 bytes of the random seed
    ld b, a  ; store a copy of a in (last byte of seed) in register b
    rept 3  ; rotate stuff around
        rl e
        rl d
        rl c
        rla
    endr
    ld h, a  ; store a copy of modified a in register h
    ; do the rotation an additional (4th) time
    rl e
    rl d
    rl c
    rla
    ; xor the current a with the original a (last byte of seed)
    xor b
    ; rotate e and d one last (5th) time, but not c
    rl e
    rl d
    ; xor a with h (old a from before the last rotation and xor),
    ; then c, then d
    xor h
    xor c
    xor d
    ; now move each byte of the seed to the next address,
    ; destroying the rightmost byte of the seed
    ld hl, wRandSeed+6
    ld de, wRandSeed+7
    push af
    ; this is lddr. Does the gameboy Z80 support it?
    rept 7
        ld a, [hld]
        ld [de], a
        dec de
    endr
    pop af
    ; store a (the new random value) as the new 1st byte of the seed
    ld [de], a
    ret