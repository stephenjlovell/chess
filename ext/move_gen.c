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

#include "move_gen.h"

static BB castle_queenside_intervening[2] = {0};
static BB castle_kingside_intervening[2] = {0};

static const int C_WQ = 0x8;
static const int C_WK = 0x4;
static const int C_BQ = 0x2;
static const int C_BK = 0x1;

void setup_castle_masks(){
  castle_queenside_intervening[1] |= (sq_mask_on(B1)|sq_mask_on(C1)|sq_mask_on(D1));
  castle_kingside_intervening[1]  |= (sq_mask_on(F1)|sq_mask_on(G1));
  castle_queenside_intervening[0] = castle_queenside_intervening[1]<<56;
  castle_kingside_intervening[0] = castle_kingside_intervening[1]<<56;  
}

BB scan_down(BB occ, enumDir dir, enumSq sq) {
  BB ray = ray_masks[dir][sq];
  BB blockers = (ray & occ);
  if(blockers) ray ^= (ray_masks[dir][msb(blockers)]);
  return ray;
}

BB scan_up(BB occ, enumDir dir, enumSq sq) {
  BB ray = ray_masks[dir][sq];
  BB blockers = (ray & occ);
  if(blockers) ray ^= (ray_masks[dir][lsb(blockers)]);
  return ray;
}

BB rook_attacks(BB occ, enumSq sq) {
  BB attacks = 0;
  attacks |= scan_up(occ, NORTH, sq);
  attacks |= scan_up(occ, EAST, sq);
  attacks |= scan_down(occ, SOUTH, sq);
  attacks |= scan_down(occ, WEST, sq);
  return attacks;
} 

BB bishop_attacks(BB occ, enumSq sq) {
  return scan_up(occ, NW, sq)|scan_up(occ, NE, sq)|scan_down(occ, SE, sq)|scan_down(occ, SW, sq);
}

BB queen_attacks(BB occ, enumSq sq){
  return (bishop_attacks(occ, sq) | rook_attacks(occ, sq));
}                                                 


static VALUE get_non_captures(VALUE self, VALUE p_board, VALUE color, VALUE castle_rights, VALUE moves){

  BRD *cBoard = get_cBoard(p_board);
  int c = SYM2COLOR(color);     
  int from, to;
  BB occupied = Occupied();
  BB empty = ~occupied;
  VALUE piece_id;
  VALUE move;

  BB single_advances, double_advances;

  // // Castles
  // int castle = NUM2INT(castle_rights);
  // if(c){
  //   if ((castle & C_WQ) && !(castle_queenside_intervening[c] & occupied)){
  //     build_castle(0x1b, E1, C1, 0x17, A1, D1, moves)
  //   }
  //   if ((castle & C_WK) && !(castle_kingside_intervening[c] & occupied)){
  //     build_castle(0x1b, E1, G1, 0x17, H1, F1, moves)
  //   }
  // } else {
  //   if ((castle & C_BQ) && !(castle_queenside_intervening[c] & occupied)){
  //     build_castle(0x1a, E8, C8, 0x16, A8, D8, moves)
  //   }
  //   if ((castle & C_BK) && !(castle_kingside_intervening[c] & occupied)){
  //     build_castle(0x1a, E8, C8, 0x16, A8, D8, moves)
  //   }
  // }

  // Pawns
  //  Pawns behave differently than other pieces. They: 
  //  1. can move only in one direction;
  //  2. can attack diagonally but can only advance on file (forward);
  //  3. can move an extra space from the starting square;
  //  4. can capture other pawns via the En-Passant Rule;
  //  5. are promoted to another piece type if they reach the enemy's back rank.

  // assert(!(cBoard->occupied[1] & cBoard->occupied[0]));

  piece_id = INT2NUM(0x10|c);
  if(c){ // white to move
    single_advances = (cBoard->pieces[WHITE][PAWN]<<8) & empty & (~row_masks[7]); // promotions generated in get_captures
    double_advances = ((single_advances & row_masks[2])<<8) & empty;
  } else { // black to move
    single_advances = (cBoard->pieces[BLACK][PAWN]>>8) & empty & (~row_masks[0]);  
    double_advances = ((single_advances & row_masks[5])>>8) & empty;
  }

  for(; double_advances; clear_sq(to, double_advances)){
    to = furthest_forward(c, double_advances);
    build_move(piece_id, to+pawn_from_offsets[c][1], to, cls_enp_advance, moves);
  }
  for(; single_advances; clear_sq(to, single_advances)){
    to = furthest_forward(c, single_advances);
    build_move(piece_id, to+pawn_from_offsets[c][0], to, cls_pawn_move, moves);  
  }

  // Knights
  piece_id = INT2NUM(0x12|c); // get knight piece ID for color c.
  for(BB f = cBoard->pieces[c][KNIGHT]; f; clear_sq(from, f)){
    from = furthest_forward(c, f); // Locate each knight for the side to move.
    for(BB t = (knight_masks[from] & empty); t; clear_sq(to, t)){ // generate to squares
      to = furthest_forward(c, t);
      build_move(piece_id, from, to, cls_regular_move, moves);
    }
  }
  // Bishops
  piece_id = INT2NUM(0x14|c); // get bishop piece ID for color c.
  for(BB f = cBoard->pieces[c][BISHOP]; f; clear_sq(from, f)){
    from = furthest_forward(c, f);
    for(BB t = (bishop_attacks(occupied, from) & empty); t; clear_sq(to, t)){ // generate to squares
      to = furthest_forward(c, t);
      build_move(piece_id, from, to, cls_regular_move, moves);
    }
  }

  // Rooks
  piece_id = INT2NUM(0x16|c); // get rook piece ID for color c.
  for(BB f = cBoard->pieces[c][ROOK]; f; clear_sq(from, f)){
    from = furthest_forward(c, f);
    for(BB t = (rook_attacks(occupied, from) & empty); t; clear_sq(to, t)){ // generate to squares
      to = furthest_forward(c, t);
      build_move(piece_id, from, to, cls_regular_move, moves);
    }
  }
  // Queens
  piece_id = INT2NUM(0x18|c); // get queen piece ID for color c.
  for(BB f = cBoard->pieces[c][QUEEN]; f; clear_sq(from, f)){
    from = furthest_forward(c, f);
    for(BB t = (queen_attacks(occupied, from) & empty); t; clear_sq(to, t)){ // generate to squares
      to = furthest_forward(c, t);
      build_move(piece_id, from, to, cls_regular_move, moves);
    }
  }
  // Kings
  piece_id = INT2NUM(0x1a|c); // get king piece ID for color c.
  for(BB f = cBoard->pieces[c][KING]; f; clear_sq(from, f)){
    from = furthest_forward(c, cBoard->pieces[c][KING]); 
    for(BB t = (king_masks[from] & empty); t; clear_sq(to, t)){ // generate to squares
      to = furthest_forward(c, t);
      build_move(piece_id, from, to, cls_king_move, moves);
    } 
  }

  return Qnil;
}


// void build_capture(int id, int from, int to, VALUE cls, VALUE sq_board, VALUE moves){                
//   VALUE args[4], strat_args[1];                                                              
//   strat_args[0] = rb_ary_entry(sq_board, to);                                       
//   VALUE strategy = rb_class_new_instance(1, strat_args, cls);                       
//   args[0] = id;                                                               
//   args[1] = INT2NUM(from);                                                    
//   args[2] = INT2NUM(to);                                                      
//   args[3] = strategy;
//   VALUE move = rb_class_new_instance(4, args, cls_move);                                                 
//   rb_ary_push(moves, move);               
// } 

// Pawn promotions are also generated during get_captures routine.

static VALUE get_captures(VALUE self, VALUE p_board, VALUE color, VALUE sq_board, VALUE enp_target, VALUE moves, VALUE promotions){
  BRD *cBoard = get_cBoard(p_board);

  int c = SYM2COLOR(color); // color of side to move
  int from, to;
  BB occupied = Occupied();
  BB enemy = Placement(c^1);
  VALUE piece_id;


  // Pawns
  piece_id = INT2NUM(0x10|c);
  BB left_temp, right_temp, left_attacks, right_attacks; 
  BB promotion_captures_left, promotion_captures_right, promotion_advances;

  if(c){ // white to move
    left_temp = ((cBoard->pieces[c][PAWN] & (~column_masks[0]))<<7) & enemy;
    left_attacks =  left_temp & (~row_masks[7]);
    promotion_captures_left = left_temp & (row_masks[7]);
    
    right_temp = ((cBoard->pieces[c][PAWN] & (~column_masks[7]))<<9) & enemy;
    right_attacks = right_temp & (~row_masks[7]);
    promotion_captures_right = right_temp & (row_masks[7]);
    
    promotion_advances = ((cBoard->pieces[c][PAWN]<<8) & row_masks[7]) & (~occupied);
  } else { // black to move
    left_temp = ((cBoard->pieces[c][PAWN] & (~column_masks[0]))>>9) & enemy;
    left_attacks =  left_temp & (~row_masks[0]);
    promotion_captures_left = left_temp & (row_masks[0]);

    right_temp = ((cBoard->pieces[c][PAWN] & (~column_masks[7]))>>7) & enemy;
    right_attacks = right_temp & (~row_masks[0]);
    promotion_captures_right = right_temp & (row_masks[0]);
    
    promotion_advances = ((cBoard->pieces[c][PAWN]>>8) & row_masks[0]) & (~occupied); 
  }

  // // promotion captures
  // for(; promotion_captures_left; clear_sq(to, promotion_captures_left)){
  //   to = furthest_forward(c, promotion_captures_left);
  //   build_capture(piece_id, to+pawn_from_offsets[c][2], to, cls_promotion_capture, sq_board, promotions);
  // }
  // for(; promotion_captures_right; clear_sq(to, promotion_captures_right)){
  //   to = furthest_forward(c, promotion_captures_right);
  //   build_capture(piece_id, to+pawn_from_offsets[c][3], to, cls_promotion_capture, sq_board, promotions);
  // }
  // // promotion advances
  // for(; promotion_advances; clear_sq(to, promotion_advances)){
  //   to = furthest_forward(c, promotion_advances);
  //   build_promotion(piece_id, to+pawn_from_offsets[c][0], to, color, cls_promotion, promotions); 
  // }
  // // regular pawn attacks
  // for(; left_attacks; clear_sq(to, left_attacks)){
  //   to = furthest_forward(c, left_attacks);
  //   build_capture(piece_id, to+pawn_from_offsets[c][2], to, cls_regular_capture, sq_board, moves);
  // }
  // for(; right_attacks; clear_sq(to, right_attacks)){
  //   to = furthest_forward(c, right_attacks);
  //   build_capture(piece_id, to+pawn_from_offsets[c][3], to, cls_regular_capture, sq_board, moves);
  // }

  // // en-passant captures
  // if(enp_target != Qnil){
  //   int target = NUM2INT(enp_target);
  //   for(BB f = cBoard->pieces[c][PAWN] & (pawn_enp_masks[target]); f; clear_sq(from, f)){
  //     from = furthest_forward(c, f);
  //     build_enp_capture(piece_id, from, (c?(target+8):(target-8)), cls_enp_capture, target, sq_board, moves);   
  //   }
  // }

  // Knights
  piece_id = INT2NUM(0x12|c); // get knight piece ID for color c.
  for(BB f = cBoard->pieces[c][KNIGHT]; f; clear_sq(from, f)){
    from = furthest_forward(c, f);
    for(BB t = (knight_masks[from] & enemy); t; clear_sq(to, t)){ // generate to squares
      to = furthest_forward(c, t);
      build_capture(piece_id, from, to, cls_regular_capture, sq_board, moves);
    }
  }

  // Bishops
  piece_id = INT2NUM(0x14|c); // get bishop piece ID for color c.
  for(BB f = cBoard->pieces[c][BISHOP]; f; clear_sq(from, f)){
    from = furthest_forward(c, f);
    for(BB t = (bishop_attacks(occupied, from) & enemy); t; clear_sq(to, t)){ // generate to squares
      to = furthest_forward(c, t);
      build_capture(piece_id, from, to, cls_regular_capture, sq_board, moves);
    }
  }
  // Rooks
  piece_id = INT2NUM(0x16|c); // get rook piece ID for color c.
  for(BB f = cBoard->pieces[c][ROOK]; f; clear_sq(from, f)){
    from = furthest_forward(c, f);
    for(BB t = (rook_attacks(occupied, from) & enemy); t; clear_sq(to, t)){ // generate to squares
      to = furthest_forward(c, t);
      build_capture(piece_id, from, to, cls_regular_capture, sq_board, moves);
    }
  }
  // Queens
  piece_id = INT2NUM(0x18|c); // get queen piece ID for color c.
  for(BB f = cBoard->pieces[c][QUEEN]; f; clear_sq(from, f)){
    from = furthest_forward(c, f);
    for(BB t = (queen_attacks(occupied, from) & enemy); t; clear_sq(to, t)){ // generate to squares
      to = furthest_forward(c, t);
      build_capture(piece_id, from, to, cls_regular_capture, sq_board, moves);
    }
  }
  // King
  piece_id = INT2NUM(0x1a|c); // get king piece ID for color c.
  for(BB f = cBoard->pieces[c][KING]; f; clear_sq(from, f)){
    from = furthest_forward(c, cBoard->pieces[c][KING]);
    for(BB t = (king_masks[from] & enemy); t; clear_sq(to, t)){ // generate to squares
      to = furthest_forward(c, t);
      build_capture(piece_id, from, to, cls_king_capture, sq_board, moves);
    }
  }

  return Qnil;
}


extern void Init_move_gen(){
  printf("  -Loading move_gen extension...");

  setup_castle_masks();

  mod_chess  = rb_define_module("Chess");
  mod_move   = rb_define_module_under(mod_chess, "Move");
  mod_move_gen = rb_define_module_under(mod_chess, "MoveGen");

  cls_move   = rb_define_class_under(mod_move, "Move", rb_cObject);
  cls_move_strategy = rb_define_class_under(mod_move, "MoveStrategy", rb_cObject);

  cls_regular_move = rb_define_class_under(mod_move, "RegularMove", cls_move_strategy);
  cls_pawn_move = rb_define_class_under(mod_move, "PawnMove", cls_move_strategy);

  cls_enp_advance = rb_define_class_under(mod_move, "EnPassantAdvance", cls_move_strategy);
  cls_enp_capture = rb_define_class_under(mod_move, "EnPassantCapture", cls_move_strategy);
  cls_promotion = rb_define_class_under(mod_move, "PawnPromotion", cls_move_strategy);
  cls_promotion_capture = rb_define_class_under(mod_move, "PawnPromotionCapture", cls_move_strategy);

  cls_regular_capture = rb_define_class_under(mod_move, "RegularCapture", cls_move_strategy);

  cls_king_move = rb_define_class_under(mod_move, "KingMove", cls_move_strategy);
  cls_king_capture = rb_define_class_under(mod_move, "KingCapture", cls_move_strategy);
  cls_castle = rb_define_class_under(mod_move, "Castle", cls_move_strategy);

  rb_define_module_function(mod_move_gen, "get_non_captures", get_non_captures, 4);
  rb_define_module_function(mod_move_gen, "get_captures", get_captures, 6);

  printf("done.\n");
}












