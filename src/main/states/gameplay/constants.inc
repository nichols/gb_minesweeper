


; If all of these are already defined, don't do it again.

    IF !DEF(CONSTANTS_INC)
DEF CONSTANTS_INC EQU 1


DEF MASK_HAS_MINE                       EQU %10000000
DEF MASK_COVERED_SQUARE_STATE           EQU %01100000


DEF MASK_CLEAR_COVERED_SQUARE_AND       EQU %10011111
DEF MASK_SET_MINE_OR                    EQU %10000000


; An adjacency bitmask uses one bit for each neighbor in this order
; (left to right, most significant to least significant)
; UL, U, UR, R, DR, D, DL, L

DEF MASK_ADJACENCY_CLEAR_ROW_ABOVE_AND  EQU %00011111
DEF MASK_ADJACENCY_CLEAR_ROW_BELOW_AND  EQU %11110001
DEF MASK_ADJACENCY_CLEAR_COL_LEFT_AND   EQU %01111100
DEF MASK_ADJACENCY_CLEAR_COL_RIGHT_AND  EQU %11000111

; is it not possible to use constants as arguments to the bit op?
; DEF BIT_ADJACENCY_MASK_UL               EQU 7
; DEF BIT_ADJACENCY_MASK_U                EQU 6
; DEF BIT_ADJACENCY_MASK_UR               EQU 5
; DEF BIT_ADJACENCY_MASK_R                EQU 4
; DEF BIT_ADJACENCY_MASK_DR               EQU 3
; DEF BIT_ADJACENCY_MASK_D                EQU 2
; DEF BIT_ADJACENCY_MASK_DL               EQU 1
; DEF BIT_ADJACENCY_MASK_L                EQU 0


; Mine data for a square that's covered without flag or ?, no bomb,
; no adjacent bombs. All squares are initialized this way at the very
; beginning of a game before bombs are added.
DEF MASK_CREATE_COVERED_SQUARE_NO_BOMBS  EQU %01100000


ENDC ;CONSTANTS_INC