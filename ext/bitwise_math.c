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

#include "ruby_chess.h"

static VALUE object_lsb(VALUE rb_self, VALUE x) { 
  x = NUM2ULONG(x);             // Return the index of the least 
  x = lsb(x);                   // significant bit of integer x.
  return ULONG2NUM(x);
}

static VALUE object_msb(VALUE rb_self, VALUE x) {  
  x = NUM2ULONG(x);             // Return the index of the most 
  x = msb(x);   // significant bit of integer x.
  return ULONG2NUM(x);
}

static VALUE object_pop_count(VALUE rb_self, VALUE x) {  
  x = NUM2ULONG(x);             // Return the population count (Hamming Weight)
  x = pop_count(x);    // of binary 1s in the integer x.  
  return ULONG2NUM(x);      
}


void Init_bitwise_math(){
  printf("Now lets do some bitwise operations.\n");

  VALUE mod_chess = rb_define_module("Chess");
  VALUE mod_bitboard = rb_define_module_under(mod_chess, "Bitboard");

  // set up module helper functions
  rb_define_module_function(mod_bitboard, "lsb", object_lsb, 1);
  rb_define_module_function(mod_bitboard, "msb", object_msb, 1);
  rb_define_module_function(mod_bitboard, "pop_count", object_pop_count, 1);


}

















