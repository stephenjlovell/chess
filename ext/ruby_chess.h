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

#ifndef RUBY_CHESS_H
#define RUBY_CHESS_H

#include <stdio.h>
#include <stdlib.h>
#include "ruby.h"


#define on_board(sq) (!!(sq & 0xffffffffffffffff))
#define column(sq) (sq >> 3)
#define row(sq) (sq & 7)
#define manhattan_distance(from, to) (abs(row(from)-row(to))+(abs(column(from)-column(to))))


typedef unsigned long BB;
typedef enum { NORTH, EAST, NW, NE, SOUTH, WEST, SE, SW } enumDir;

typedef enum {  A1, B1, C1, D1, E1, F1, G1, H1, 
                A2, B2, C2, D2, E2, F2, G2, H2, 
                A3, B3, C3, D3, E3, F3, G3, H3, 
                A4, B4, C4, D4, E4, F4, G4, H4, 
                A5, B5, C5, D5, E5, F5, G5, H5, 
                A6, B6, C6, D6, E6, F6, G6, H6, 
                A7, B7, C7, D7, E7, F7, G7, H7, 
                A8, B8, C8, D8, E8, F8, G8, H8  } enumSq;


static BB uni_mask = 0xffffffffffffffff;
static BB empty_mask = 0x0;
static BB consecutive_bits[64] = {0};
static BB row_masks[8] = {0};
static BB column_masks[8] = {0};
static BB pawn_masks[2][64] = { {0}, {0} };
static BB knight_masks[64] = {0};
static BB bishop_masks[64] = {0};
static BB rook_masks[64] = {0};
static BB queen_masks[64] = {0};
static BB king_masks[64] = {0};
static BB square_keys[64] = {0};
static BB ray_masks[8][64] = { {0},{0},{0},{0},{0},{0},{0},{0} };

// Include child header files
#include "bitboard.h"
#include "bitwise_math.h"
#include "move_gen.h"



void Init_ruby_chess();


#endif



