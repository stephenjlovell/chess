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

BRD *current_board = NULL;

void free_cBoard(BRD *b){
  current_board = NULL;
  ruby_xfree(b);
}

static BRD* get_cBoard(VALUE self){
  BRD *b;
  Data_Get_Struct(self, BRD, b);
  return b;
}

static VALUE o_alloc(VALUE klass){
  return Data_Wrap_Struct(klass, 0, free_cBoard, ruby_xmalloc(sizeof(BRD)));
}

static VALUE o_initialize(VALUE self, VALUE sq_board){
  BRD board = { { {0}, {0} }, {0} };
  BRD *b = get_cBoard(self);
  *b = board;
  current_board = b;
  rb_funcall(self, rb_intern("setup"), 1, sq_board);

  return self;
}

static VALUE o_setup(VALUE self, VALUE sq_board){
  return Qnil;
}

static VALUE o_get_bitboard(VALUE self, VALUE piece_id){
  int id = NUM2INT(piece_id);
  return ULONG2NUM(get_cBoard(self)->pieces[piece_color(id)][piece_type(id)]);    
}

static VALUE o_get_king_square(VALUE self, VALUE color_sym){
  return INT2NUM(lsb(get_cBoard(self)->pieces[SYM2COLOR(color_sym)][5]));
}

static VALUE o_get_occupancy(VALUE self, VALUE color_sym){
  return ULONG2NUM(get_cBoard(self)->occupied[SYM2COLOR(color_sym)]);
}

static VALUE o_set_bitboard(VALUE self, VALUE piece_id, VALUE bitboard){
  int id = NUM2INT(piece_id);
  get_cBoard(self)->pieces[piece_color(id)][piece_type(id)] = NUM2ULONG(bitboard);
  return bitboard;
}

static VALUE o_add_square(VALUE self, VALUE piece_id, VALUE square){
  int sq = NUM2INT(square);
  int id = NUM2INT(piece_id);
  int c = piece_color(id);
  BRD *b = get_cBoard(self);
  add_sq(sq, b->pieces[c][piece_type(id)]);
  add_sq(sq, b->occupied[c]);
  return Qnil;  
}

static VALUE o_remove_square(VALUE self, VALUE piece_id, VALUE square){
  int sq = NUM2INT(square);
  int id = NUM2INT(piece_id);
  int c = piece_color(id);
  BRD *b = get_cBoard(self);
  clear_sq(sq, b->pieces[c][piece_type(id)]);
  clear_sq(sq, b->occupied[c]);
  return Qnil;  
}

static VALUE o_relocate_piece(VALUE self, VALUE piece_id, VALUE from, VALUE to){
  int id = NUM2INT(piece_id);
  from = NUM2INT(from);
  to = NUM2INT(to);
  int t = piece_type(piece_id);
  int c = piece_color(piece_id);
  int delta = sq_mask_on(from)|sq_mask_on(to);
  BRD *b = get_cBoard(self);
  b->pieces[c][t] ^= delta;
  b->occupied[c] ^= delta;
  return Qnil;
}


extern void Init_board(){
  printf("  -Loading board extension...");

  VALUE mod_chess = rb_define_module("Chess");
  VALUE mod_bitboard = rb_define_module_under(mod_chess, "Bitboard");
  VALUE cls_board = rb_define_class_under(mod_bitboard, "PiecewiseBoard", rb_cObject);
  
  rb_define_alloc_func(cls_board, o_alloc);
  
  rb_define_method(cls_board, "get_bitboard", RUBY_METHOD_FUNC(o_get_bitboard), 1);
  rb_define_method(cls_board, "get_king_square", RUBY_METHOD_FUNC(o_get_king_square), 1);
  rb_define_method(cls_board, "get_occupancy", RUBY_METHOD_FUNC(o_get_occupancy), 1);
  rb_define_method(cls_board, "set_bitboard", RUBY_METHOD_FUNC(o_set_bitboard), 2);

  rb_define_method(cls_board, "add_square", RUBY_METHOD_FUNC(o_add_square), 2);
  rb_define_method(cls_board, "remove_square", RUBY_METHOD_FUNC(o_add_square), 2);
  rb_define_method(cls_board, "relocate_piece", RUBY_METHOD_FUNC(o_relocate_piece), 3);
  rb_define_method(cls_board, "initialize", RUBY_METHOD_FUNC(o_initialize), 1);

  rb_define_private_method(cls_board, "setup", RUBY_METHOD_FUNC(o_setup), 0);

  printf("done.\n");
}






