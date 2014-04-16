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

#ifndef MOVE_GEN
#define MOVE_GEN

#include "shared.h"
#include "board.h"
#include "bitwise_math.h"

BB get_ray_attacks_reverse(BB occupied, enumDir dir, enumSq sq);
BB get_ray_attacks_forward(BB occupied, enumDir dir, enumSq sq);
BB get_bishop_attacks(BB occupied, enumSq sq);
BB get_rook_attacks(BB occupied, enumSq sq);
BB get_queen_attacks(BB occupied, enumSq sq);

VALUE get_knight_non_captures(VALUE self, VALUE knights, VALUE occupied);
VALUE get_knight_captures(VALUE self, VALUE knights, VALUE enemy);

VALUE get_bishop_non_captures(VALUE self, VALUE bishops, VALUE occupied);
VALUE get_bishop_captures(VALUE self, VALUE bishops, VALUE occupied, VALUE enemy);

VALUE get_rook_non_captures(VALUE self, VALUE rooks, VALUE occupied);
VALUE get_rook_captures(VALUE self, VALUE rooks, VALUE occupied, VALUE enemy);

VALUE get_queen_non_captures(VALUE self, VALUE queens, VALUE occupied);
VALUE get_queen_captures(VALUE self, VALUE queens, VALUE occupied, VALUE enemy);

VALUE get_king_non_captures(VALUE self, VALUE kings, VALUE occupied);
VALUE get_king_captures(VALUE self, VALUE kings, VALUE enemy);

extern void Init_move_gen();


#endif






