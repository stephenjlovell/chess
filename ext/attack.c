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

#include "attack.h"


BB attack_map(VALUE p_board, enumSq sq){
  BB attacks = 0;
  BRD *cBoard = get_cBoard(p_board);
  BB occ = Occupied();
  // Pawns
  attacks |= (pawn_attack_masks[BLACK][sq] & cBoard->pieces[WHITE][PAWN]) |
             (pawn_attack_masks[WHITE][sq] & cBoard->pieces[BLACK][PAWN]);
  // Knights
  attacks |= (knight_masks[sq] & (cBoard->pieces[WHITE][KNIGHT]|cBoard->pieces[BLACK][KNIGHT]));
  // Bishops and Queens
  BB b_attackers = cBoard->pieces[WHITE][BISHOP] | cBoard->pieces[BLACK][BISHOP] | 
                   cBoard->pieces[WHITE][QUEEN]  | cBoard->pieces[BLACK][QUEEN];
  attacks |= (bishop_attacks(occ, sq) & b_attackers);
  // Rooks and Queens
  BB r_attackers = cBoard->pieces[WHITE][ROOK]  | cBoard->pieces[BLACK][ROOK] | 
                   cBoard->pieces[WHITE][QUEEN] | cBoard->pieces[BLACK][QUEEN];
  attacks |= (rook_attacks(occ, sq) & r_attackers);
  // Kings
  attacks |= (king_masks[sq] & (cBoard->pieces[WHITE][KING]|cBoard->pieces[BLACK][KING]));
  return attacks;
}

int is_attacked_by(BRD *cBoard, enumSq sq, int c){
  int e = c^1;  // enemy color
  BB occ = Occupied();
  // Pawns
  if(pawn_attack_masks[c][sq] & cBoard->pieces[e][PAWN]) return 1; 
  // Knights
  if(knight_masks[sq] & (cBoard->pieces[e][KNIGHT])) return 1;
  // Bishops and Queens
  if(bishop_attacks(occ, sq) & (cBoard->pieces[e][BISHOP]|cBoard->pieces[e][QUEEN])) return 1;
  // Rooks and Queens
  if(rook_attacks(occ, sq) & (cBoard->pieces[e][ROOK]|cBoard->pieces[e][QUEEN])) return 1;
  // Kings
  if(king_masks[sq] & (cBoard->pieces[e][KING])) return 1;
  return 0;
}

VALUE is_in_check(VALUE self, VALUE p_board, VALUE side_to_move){
  BRD *cBoard = get_cBoard(p_board);
  int c = SYM2COLOR(side_to_move);

  // handle king loss here.

  return (is_attacked_by(cBoard, furthest_forward(c, cBoard->pieces[c][KING]), c) ? Qtrue : Qfalse);
}

static VALUE move_evades_check(VALUE self, VALUE p_board, VALUE sq_board, 
                               VALUE from, VALUE to, VALUE color){
  BRD *cBoard = get_cBoard(p_board);
  int c = SYM2COLOR(color);
  int e = c^1;
  int f = NUM2INT(from), t = NUM2INT(to);
  int check;

  int piece = NUM2INT(rb_ary_entry(sq_board, f));  // ?
  int captured_piece = NUM2INT(rb_ary_entry(sq_board, t));

  BB own_king = cBoard->pieces[c][KING];
  if(!own_king) return Qfalse;

  BB delta = (sq_mask_on(t)|sq_mask_on(f));
  cBoard->pieces[c][piece_type(piece)] ^= delta;
  cBoard->occupied[c] ^= delta;

  if(captured_piece){
    clear_sq(t, cBoard->pieces[e][piece_type(captured_piece)]);
    clear_sq(t, cBoard->occupied[e]);
    // determine if in check
    check = is_attacked_by(cBoard, furthest_forward(c, cBoard->pieces[c][KING]), c);
    add_sq(t, cBoard->pieces[e][piece_type(captured_piece)]);
    add_sq(t, cBoard->occupied[e]);
  } else {
    // determine if in check
    check = is_attacked_by(cBoard, furthest_forward(c, cBoard->pieces[c][KING]), c);
  }
  cBoard->pieces[c][piece_type(piece)] ^= delta;
  cBoard->occupied[c] ^= delta;

  return (check ? Qfalse : Qtrue);
}


// The Static Exchange Evaluation (SEE) heuristic provides a way to determine if a capture 
// is a 'winning' or 'losing' capture.

// 1. When a capture results in an exchange of pieces by both sides, SEE is used to determine the 
//    net gain/loss in material for the side initiating the exchange.
// 2. SEE scoring of moves is used for move ordering of captures at critical nodes.
// 3. During quiescence search, SEE is used to prune losing captures. This provides a very low-risk
//    way of reducing the size of the q-search without impacting playing strength.

static VALUE static_exchange_evaluation(VALUE self, VALUE p_board, VALUE from, VALUE to, VALUE side_to_move, VALUE sq_board){
  BRD *cBoard = get_cBoard(p_board);
  from = (NUM2INT(from));
  to = (NUM2INT(to));
  int c = SYM2COLOR(side_to_move);
  int next_victim, type;
  int temp_color = c;
  int score = 0;

  // get initial map of all squares directly attacking this square (does not include 'discovered'/hidden attacks)
  const BB b_attackers = cBoard->pieces[WHITE][BISHOP] | cBoard->pieces[BLACK][BISHOP] | 
                         cBoard->pieces[WHITE][QUEEN]  | cBoard->pieces[BLACK][QUEEN];
  const BB r_attackers = cBoard->pieces[WHITE][ROOK]  | cBoard->pieces[BLACK][ROOK] | 
                         cBoard->pieces[WHITE][QUEEN] | cBoard->pieces[BLACK][QUEEN];

  BB temp_map = attack_map(p_board, to);
  BB temp_occ = Occupied();
  int alpha = -1000000;
  int beta =   1000000;
  BB temp_pieces;

  // before entering the main loop, perform each step once for the initial attacking piece.  This ensures that the
  // moved piece is the first to capture.
  type = piece_type_at(sq_board, from);
  alpha = score;
  score += piece_value_at(sq_board, to);

  next_victim = piece_value_at(sq_board, from);
  clear_sq(from, temp_occ);
  if(type != KNIGHT && type != KING){ // if the attacker was a pawn, bishop, rook, or queen, re-scan for hidden attacks:
    if(type == PAWN || type == BISHOP || type == QUEEN) temp_map |= bishop_attacks(temp_occ, to) & b_attackers;
    if(type == PAWN || type == ROOK   || type == QUEEN) temp_map |= rook_attacks(temp_occ, to) & r_attackers;
  }
  temp_color^=1;

  for(temp_map &= temp_occ; temp_map; temp_map &= temp_occ){
    for(type = PAWN; type <= KING; type++){ // loop over piece types in order of value.
      temp_pieces = cBoard->pieces[temp_color][type] & temp_map;
      if(temp_pieces) break; // stop as soon as a match is found.
    }
    if(type > KING) break;

    if(c == temp_color){    // iterative alpha-beta:
      if(score >= beta) return INT2NUM(beta);
      if(score > alpha) alpha = score;
      score += next_victim;
    } else {
      if(score <= alpha) return INT2NUM(alpha);
      if(score < beta) beta = score;
      score -= next_victim;
    }

    next_victim = piece_values[type];
    temp_occ ^= (temp_pieces & -temp_pieces);  // merge the first set bit of temp_pieces into temp_occ
    if(type != KNIGHT && type != KING){
      if(type == PAWN || type == BISHOP || type == QUEEN) temp_map |= (bishop_attacks(temp_occ, to) & b_attackers);
      if(type == ROOK || type == QUEEN) temp_map |= (rook_attacks(temp_occ, to) & r_attackers);
    }
    temp_color^=1;

  }
  return INT2NUM(score);
}

extern void Init_attack(){
  VALUE mod_chess = rb_define_module("Chess");
  VALUE cls_position = rb_define_class_under(mod_chess, "Position", rb_cObject);
  rb_define_method(cls_position, "side_in_check?", RUBY_METHOD_FUNC(is_in_check), 2);
  rb_define_method(cls_position, "move_evades_check?", RUBY_METHOD_FUNC(move_evades_check), 5);

  VALUE mod_search = rb_define_module_under(mod_chess, "Search");
  rb_define_module_function(mod_search, "static_exchange_evaluation", static_exchange_evaluation, 5);
}














