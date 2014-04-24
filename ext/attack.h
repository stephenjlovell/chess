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

#define piece_value_at(sq_board, sq) (piece_values[piece_type(rb_ary_entry(sq_board, sq))])
#define piece_type_at(sq_board, sq) (piece_type(NUM2INT(rb_ary_entry(sq_board, sq))))


static VALUE mod_chess;
static VALUE mod_position;
static VALUE mod_search;

BB update_temp_map(BB temp_map, BB temp_occ, BB b_attackers, BB r_attackers, int type, int sq);

BB attack_map(enumSq sq);

int is_attacked(enumSq sq);

VALUE is_in_check(VALUE self, VALUE side_to_move);

VALUE static_exchange_evaluation(VALUE self, VALUE from, VALUE to, VALUE side_to_move, VALUE sq_board);




extern void Init_attack();

#endif
