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

// This module wraps a Ruby object around a BRD struct to make it accessible and provide methods for
// manipulating it efficiently from Ruby.

#include "shared.h"

void add_square(int color, int type, int sq);

static void free_cBoard(BRD* board);
extern BRD* get_cBoard(VALUE self);
static VALUE o_alloc(VALUE klass);
static VALUE o_initialize(VALUE self, VALUE sq_board);

static VALUE o_get_bitboard(VALUE self, VALUE piece_id);
static VALUE o_get_king_square(VALUE self, VALUE color_sym);
static VALUE o_get_occupancy(VALUE self, VALUE color_sym);
static VALUE o_set_bitboard(VALUE self, VALUE piece_id, VALUE bitboard);
static VALUE o_remove_square(VALUE self, VALUE piece_id, VALUE square);
static VALUE o_move_update(VALUE self, VALUE piece_id, VALUE from, VALUE to);

static VALUE o_initialize_material(VALUE self, VALUE color);
static VALUE o_get_base_material(VALUE self, VALUE color);

extern void Init_board();
  
#endif






