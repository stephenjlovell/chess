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

void free_cBoard(BRD *b){
  ruby_xfree(b);
}

extern BRD* get_cBoard(VALUE self){
  BRD *b;
  Data_Get_Struct(self, BRD, b);
  return b;
}

static VALUE o_alloc(VALUE klass){
  return Data_Wrap_Struct(klass, 0, free_cBoard, ruby_xmalloc(sizeof(BRD)));
}

static VALUE o_initialize(VALUE self, VALUE sq_board){
  BRD blank_board = { { {0}, {0} }, {0} };
  BRD *cBoard = get_cBoard(self);
  *cBoard = blank_board;
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
  return INT2NUM(lsb(get_cBoard(self)->pieces[SYM2COLOR(color_sym)][KING]));
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
  BRD *cBoard = get_cBoard(self);
  int sq = NUM2INT(square);
  int id = NUM2INT(piece_id);
  int c = piece_color(id);
  int t = piece_type(id);

  add_sq(sq, cBoard->pieces[c][t]);
  add_sq(sq, cBoard->occupied[c]);
  cBoard->material[c] += piece_values[t]; // Incrementally update material.
  return Qnil;  
}

static VALUE o_remove_square(VALUE self, VALUE piece_id, VALUE square){
  BRD *cBoard = get_cBoard(self);
  int sq = NUM2INT(square);
  int id = NUM2INT(piece_id);
  int  c = piece_color(id);
  int  t = piece_type(id); 

  clear_sq(sq, cBoard->pieces[c][t]);
  clear_sq(sq, cBoard->occupied[c]);
  cBoard->material[c] -= piece_values[t];  // Incrementally update material.
  return Qnil;  
}

static VALUE o_relocate_piece(VALUE self, VALUE piece_id, VALUE from, VALUE to){
  BRD *cBoard = get_cBoard(self);  
  int type = piece_type(NUM2INT(piece_id));
  int c = piece_color(NUM2INT(piece_id));
  int f = NUM2INT(from);
  int t = NUM2INT(to);

  BB delta = (sq_mask_on(t)|sq_mask_on(f));
  cBoard->pieces[c][type] ^= delta;
  cBoard->occupied[c] ^= delta;
  return Qnil;
}

static VALUE o_get_base_material(VALUE self, VALUE color){
  BRD *cBoard = get_cBoard(self);
  return INT2NUM(cBoard->material[SYM2COLOR(color)]);
}

static VALUE o_in_endgame(VALUE self, VALUE color){
  BRD *cBoard = get_cBoard(self);
  int c = SYM2COLOR(color);
  return (cBoard->material[c] <= endgame_value) ? Qtrue : Qfalse;
}

// This method is used to check the legality of human moves prior to making the move.
static VALUE o_test_legality(VALUE self, VALUE p, VALUE f, VALUE t, VALUE side_to_move, VALUE enp_target, VALUE castle){
  BRD *cBoard = get_cBoard(self);
  int c = SYM2COLOR(side_to_move);
  int e = c^1;
  int from = NUM2INT(f);
  int to = NUM2INT(t);
  int piece = NUM2INT(p);
  BB occ = Occupied();
  BB empty = ~occ;
  BB friendly = cBoard->occupied[c];
  BB enemy = cBoard->occupied[e];
  BB piece_mask = 0;

  int moved_type = piece_type(piece);

  switch(moved_type){
    case PAWN:
      if(pawn_attack_masks[c][from] & sq_mask_on(to) & enemy) return Qtrue;
      BB single_advances, double_advances;
      if(c){
        single_advances = (cBoard->pieces[WHITE][PAWN]<<8) & empty; 
        double_advances = ((single_advances & row_masks[2])<<8) & empty;
      } else {
        single_advances = (cBoard->pieces[BLACK][PAWN]>>8) & empty;  
        double_advances = ((single_advances & row_masks[5])>>8) & empty;
      }
      if((single_advances & sq_mask_on(to)) && manhattan_distance(from, to) == 1
          && column(from) == column(to)) return Qtrue;
      if((double_advances & sq_mask_on(to)) && manhattan_distance(from, to) == 2
          && column(from) == column(to)) return Qtrue;
      if(enp_target != Qnil){
        enp_target = NUM2INT(enp_target);
        if(pawn_enp_masks[from] & sq_mask_on(enp_target)){
          if(pawn_attack_masks[c][from] & sq_mask_on(to) & empty) return Qtrue;
        }
      }
      break;
    case KING:
      if(king_masks[from] & sq_mask_on(to) & (~friendly)) return Qtrue;  // Move is pseudo-legal.
      castle = NUM2INT(castle);
      if (castle){
        if(c){
          if ((castle & C_WQ) && !(castle_queenside_intervening[1] & occ) && from == E1 && to == C1) return Qtrue;
          if(((castle & C_WK) && !(castle_kingside_intervening[1] & occ)) && from == E1 && to == G1) return Qtrue;
        } else {
          if ((castle & C_BQ) && !(castle_queenside_intervening[0] & occ) && from == E8 && to == C8) return Qtrue;
          if ((castle & C_BK) && !(castle_kingside_intervening[0] & occ) && from == E8 && to == G8) return Qtrue;
        }
      }
      break;
    default:
      switch(moved_type){
        case KNIGHT: piece_mask = knight_masks[from]; break;
        case BISHOP: piece_mask = bishop_masks[from]; break;
        case ROOK: piece_mask = rook_masks[from]; break;
        case QUEEN: piece_mask = queen_masks[from]; break;
      }
      printf("%lu\n", piece_mask);
      return (piece_mask & sq_mask_on(to) & (~friendly)) ? Qtrue : Qfalse;
      break;
  }
  return Qfalse;
}


extern void Init_board(){
  printf("  -Loading board extension...");

  VALUE mod_chess = rb_define_module("Chess");
  VALUE mod_bitboard = rb_define_module_under(mod_chess, "Bitboard");
  VALUE mod_notation = rb_define_module_under(mod_chess, "Notation");
  VALUE cls_board = rb_define_class_under(mod_bitboard, "PiecewiseBoard", rb_cObject);
  
  rb_define_alloc_func(cls_board, o_alloc);

  rb_define_method(cls_board, "initialize", RUBY_METHOD_FUNC(o_initialize), 1);
  rb_define_private_method(cls_board, "setup", RUBY_METHOD_FUNC(o_setup), 0);  

  rb_define_method(cls_board, "get_bitboard", RUBY_METHOD_FUNC(o_get_bitboard), 1);
  rb_define_method(cls_board, "get_king_square", RUBY_METHOD_FUNC(o_get_king_square), 1);
  rb_define_method(cls_board, "get_occupancy", RUBY_METHOD_FUNC(o_get_occupancy), 1);
  rb_define_method(cls_board, "set_bitboard", RUBY_METHOD_FUNC(o_set_bitboard), 2);

  rb_define_method(cls_board, "test_piece_legality", RUBY_METHOD_FUNC(o_test_legality), 6);

  rb_define_method(cls_board, "add_square", RUBY_METHOD_FUNC(o_add_square), 2);
  rb_define_method(cls_board, "remove_square", RUBY_METHOD_FUNC(o_remove_square), 2);
  rb_define_method(cls_board, "relocate_piece", RUBY_METHOD_FUNC(o_relocate_piece), 3);

  rb_define_method(cls_board, "get_base_material", RUBY_METHOD_FUNC(o_get_base_material), 1);
  rb_define_method(cls_board, "endgame?", RUBY_METHOD_FUNC(o_in_endgame), 1);

  printf("done.\n");
}






