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

#include ""
#include "ruby_chess.h"



static VALUE wrap_Board_alloc(VALUE klass){
  return Data_Wrap_Struct(klass, NULL, wrap_Board_free, ruby_xmalloc(sizeof(BOARD)));
}

static void wrap_Board_free(BOARD* board){
  ruby_xfree(board);
}

static VALUE wrap_Board_init(VALUE self, VALUE bb_hash){ 
  if(!bb_hash == Qnil){
    // Parse a Ruby hash of the form hash[piece][color] = bitboard and store each value in the struct.
  }
  return Qnil;
}


static BOARD* getBoard(VALUE self){
  BOARD* b;
  Data_Get_Struct(self, BOARD, b);
  return b;
}

static VALUE object_set_bitboard(VALUE self, VALUE piece_type, VALUE color, VALUE bitboard){
  color = SYM2ID(color);
  piece_type = SYM2ID(piece_type);
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
  } else {
    current_board.kings[side] = bitboard;
  }
  return ULONG2NUM(bitboard);
}


void Init_board(){
  printf("Loading PiecewiseBoard extension...");
  VALUE mod_chess = rb_define_module("Chess");
  VALUE mod_bitboard = rb_define_module_under(mod_chess, "Bitboard");
  VALUE class = rb_define_class_under(mod_bitboard, "PiecewiseBoard", rb_cObject);
  rb_define_alloc_func(class, wrap_Board_alloc);
  rb_define_private_method(class, "initialize", RUBY_METHOD_FUNC(wrap_Board_init), 1);
  rb_define_method(class, "set_bitboard", RUBY_METHOD_FUNC(object_set_bitboard), 3);
  printf("done.\n");


}






















