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

#include "board.h"


static VALUE wrap_Board_alloc(VALUE klass){
  return Data_Wrap_Struct(klass, NULL, wrap_Board_free, ruby_xmalloc(sizeof(BRD)));
}

static void wrap_Board_free(BRD* board){
  ruby_xfree(board);
}

static BRD* getBoard(VALUE self){
  BRD* b;
  Data_Get_Struct(self, BRD, b);
  return b;
}

static VALUE object_set_bitboard(VALUE self, VALUE piece_type, VALUE color, VALUE bitboard){
  bitboard = NUM2ULONG(bitboard);
  enumSide side;
  if (color == ID2SYM(rb_intern("w"))){
    side = WHITE;
  } else {
    side = BLACK;
  }
  if (piece_type == ID2SYM(rb_intern("P"))){
    current_board.pawns[side] = bitboard;
  } else if (piece_type == ID2SYM(rb_intern("N"))){
    current_board.knights[side] = bitboard;
  } else if (piece_type == ID2SYM(rb_intern("B"))){
    current_board.bishops[side] = bitboard;
  } else if (piece_type == ID2SYM(rb_intern("R"))){
    current_board.rooks[side] = bitboard;
  } else if (piece_type == ID2SYM(rb_intern("Q"))){
    current_board.queens[side] = bitboard;
  } else if (piece_type == ID2SYM(rb_intern("K"))){
    current_board.kings[side] = bitboard;
  } else {
    printf("bitboard not set.\n");
    return Qnil;
  }

  return ULONG2NUM(bitboard);
}


static VALUE object_get_bitboard(VALUE self, VALUE piece_type, VALUE color){

  enumSide side;
  if (color == ID2SYM(rb_intern("w"))){
    side = WHITE;
  } else {
    side = BLACK;
  }
  if (piece_type == ID2SYM(rb_intern("P"))){
    return ULONG2NUM(current_board.pawns[side]);
  } else if (piece_type == ID2SYM(rb_intern("N"))){
    return ULONG2NUM(current_board.knights[side]);
  } else if (piece_type == ID2SYM(rb_intern("B"))){
    return ULONG2NUM(current_board.bishops[side]);
  } else if (piece_type == ID2SYM(rb_intern("R"))){
    return ULONG2NUM(current_board.rooks[side]);
  } else if (piece_type == ID2SYM(rb_intern("Q"))){
    return ULONG2NUM(current_board.queens[side]);
  } else if (piece_type == ID2SYM(rb_intern("K"))){
    return ULONG2NUM(current_board.kings[side]);
  } else {
    printf("bitboard not found.\n");
    return Qnil;    
  }

}


extern void Init_board(){
  printf("  -Loading board extension...");
  VALUE mod_chess = rb_define_module("Chess");
  VALUE mod_bitboard = rb_define_module_under(mod_chess, "Bitboard");
  VALUE class = rb_define_class_under(mod_bitboard, "PiecewiseBoard", rb_cObject);
  rb_define_alloc_func(class, wrap_Board_alloc);
  // rb_define_private_method(class, "initialize", RUBY_METHOD_FUNC(wrap_Board_init), 0);
  rb_define_method(class, "get_bitboard", RUBY_METHOD_FUNC(object_get_bitboard), 2);
  rb_define_method(class, "set_bitboard", RUBY_METHOD_FUNC(object_set_bitboard), 3);
  printf("done.\n");
}






