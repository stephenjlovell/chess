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

#ifndef EVAL
#define EVAL

#include "shared.h"

void setup_eval_constants();

extern int non_king_value;
extern int endgame_value;
extern int mate_value;

static int main_pst[2][5][64];
static int king_pst[2][2][64];
static VALUE mod_chess;
static VALUE mod_eval;

#define in_endgame(color) (cBoard->material[color] <= endgame_value ? 1 : 0)


extern int get_pst(BRD *cBoard, int color, int type, int sq);
extern int get_pst_delta(BRD *cBoard, int color, int type, int from, int to);

static VALUE evaluate_material(VALUE self, VALUE pc_board, VALUE color);

static VALUE net_material(VALUE self, VALUE pc_board, VALUE color);
static VALUE net_placement(VALUE self, VALUE pc_board, VALUE color);

static int adjusted_placement(int c, BRD *cBoard);
static int adjusted_material(int c, BRD *cBoard);

static int mobility(int c, int e, BRD *cBoard);

extern void Init_eval();

#endif








