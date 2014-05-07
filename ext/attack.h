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

#ifndef ATTACK
#define ATTACK

#include "shared.h"


static VALUE mod_chess;
static VALUE mod_position;
static VALUE mod_search;

BB attack_map(BRD *cBoard, enumSq sq);
BB color_attack_map(BRD *cBoard, enumSq sq, int c, int e);

int is_attacked_by(BRD *cBoard, enumSq sq, int c);

int is_pinned(BRD* cBoard, int sq, int c, int e);

static VALUE move_evades_check(VALUE self, VALUE p_board, VALUE sq_board, 
                               VALUE from, VALUE to, VALUE color);

BB update_temp_map(BB temp_map, BB temp_occ, BB b_attackers, BB r_attackers, int type, int sq);

static VALUE static_exchange_evaluation(VALUE self, VALUE p_board, VALUE from, VALUE to, 
                                        VALUE side_to_move, VALUE sq_board);




extern void Init_attack();

#endif
