//-----------------------------------------------------------------------------------
// Copyright (c) 2013 Stephen J. Lovell
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
// the Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//-----------------------------------------------------------------------------------

#ifndef SHARED
#define SHARED

#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include "ruby.h"


typedef unsigned long BB;

typedef struct {
  BB pieces[2][6];
  BB occupied[2];
  int material[2];
} BRD;


// typedef enum { NW, NE, SE, SW, NORTH, EAST, SOUTH, WEST } enumDir;

typedef enum { NW, NE, SE, SW, NORTH, EAST, SOUTH, WEST } enumDir;



typedef enum {  A1, B1, C1, D1, E1, F1, G1, H1, 
                A2, B2, C2, D2, E2, F2, G2, H2, 
                A3, B3, C3, D3, E3, F3, G3, H3, 
                A4, B4, C4, D4, E4, F4, G4, H4, 
                A5, B5, C5, D5, E5, F5, G5, H5, 
                A6, B6, C6, D6, E6, F6, G6, H6, 
                A7, B7, C7, D7, E7, F7, G7, H7, 
                A8, B8, C8, D8, E8, F8, G8, H8, INVALID } enumSq;

typedef enum { BLACK, WHITE } enumSide;

typedef enum { PAWN, KNIGHT, BISHOP, ROOK, QUEEN, KING } enumPiece;

extern int piece_values[6]; 

// extern BRD *cBoard;

extern BB uni_mask;
extern BB empty_mask;

extern BB row_masks[8];
extern BB column_masks[8];
extern BB ray_masks[8][64];

extern BB pawn_attack_masks[2][64];
extern BB pawn_enp_masks[64];

extern int pawn_from_offsets[2][4];

extern BB knight_masks[64];
extern BB bishop_masks[64];
extern BB rook_masks[64];
extern BB queen_masks[64];
extern BB king_masks[64];

extern BB square_masks_on[64];
extern BB square_masks_off[64];


#define on_board(sq) (0 <= sq && sq <= 63)

#define row(sq) (sq >> 3)
#define column(sq) (sq & 7)

#define manhattan_distance(from, to) ((abs(row(from)-row(to)))+(abs(column(from)-column(to))))

#define SYM2COLOR(sym)    (sym == ID2SYM(rb_intern("w")) ? 1 : 0)
#define SYM2OPPCOLOR(sym) (sym == ID2SYM(rb_intern("w")) ? 0 : 1)

#define sq_mask_on(sq) (square_masks_on[sq])
#define sq_mask_off(sq) (square_masks_off[sq])

#define clear_sq(sq, bitboard) (bitboard &= sq_mask_off(sq))
#define add_sq(sq, bitboard)   (bitboard |= sq_mask_on(sq))

#define Occupied() ((cBoard->occupied[0])|(cBoard->occupied[1]))
#define Placement(color) (cBoard->occupied[color])



// Include child header files
#include "bitboard.h"
#include "bitwise_math.h"
#include "board.h"
#include "attack.h"
#include "move_gen.h"

extern void Init_ruby_chess();


#endif



