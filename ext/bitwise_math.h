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

#ifndef BITWISE_MATH
#define BITWISE_MATH

#include "shared.h"

#define lsb(bitboard) (__builtin_ctzl(bitboard))
#define msb(bitboard) (__builtin_clzl(bitboard))
#define furthest_forward(bitboard, color) (color ? msb(bitboard) : lsb(bitboard))
#define pop_count(bitboard) (__builtin_popcount(bitboard))


static VALUE object_lsb(VALUE rb_self, VALUE bitboard);
static VALUE object_msb(VALUE rb_self, VALUE bitboard);
static VALUE object_pop_count(VALUE rb_self, VALUE bitboard);
static VALUE object_add(VALUE rb_self, VALUE sq, VALUE bitboard);
static VALUE object_clear(VALUE rb_self, VALUE sq, VALUE bitboard);

extern void Init_bitwise_math();





#endif




