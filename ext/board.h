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


#ifndef BOARD
#define BOARD

#include "shared.h"

typedef struct {
  BB pawns[2];
  BB knights[2];
  BB bishops[2];
  BB rooks[2];
  BB queens[2];
  BB kings[2];
  BB all[2];
} BRD;

// This module wraps a Ruby object around the BOARD struct to make it accessible within Ruby.

static BRD current_board;
static VALUE wrap_Board_alloc(VALUE klass);
static void wrap_Board_free(BRD* board);
static VALUE wrap_Board_init(VALUE self);
static BRD* get_board(VALUE self);
static VALUE object_set_bitboard(VALUE self, VALUE piece_type, VALUE color, VALUE bitboard);
static VALUE object_get_bitboard(VALUE self, VALUE piece_type, VALUE color);

extern void Init_board();
  
#endif






