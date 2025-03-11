


; If all of these are already defined, don't do it again.

    IF !DEF(CONSTANTS_INC)
DEF CONSTANTS_INC EQU 1


DEF MASK_HAS_MINE                   EQU %10000000
DEF MASK_COVERED_SQUARE_STATE       EQU %01100000


DEF MASK_CLEAR_COVERED_SQUARE_AND   EQU %10011111
DEF MASK_SET_MINE_OR                EQU %10000000


; Mine data for a square that's covered without flag or ?, no bomb,
; no adjacent bombs. All squares are initialized this way at the very
; beginning of a game before bombs are added.
DEF MASK_CREATE_COVERED_SQUARE_NO_BOMBS  EQU %01100000


ENDC ;CONSTANTS_INC