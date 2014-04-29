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

int is_attacked_by(VALUE p_board, enumSq sq, int c){
  BRD *cBoard = get_cBoard(p_board);
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
  return (is_attacked_by(p_board, furthest_forward(c, cBoard->pieces[c][KING]), c) ? Qtrue : Qfalse);
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
  to = (NUM2INT(to));
  from = (NUM2INT(from));
  int c = SYM2COLOR(side_to_move);
  int next_victim, type;
  int temp_color = c;
  int score = 0;

  int pc_list[20];

  // get initial map of all squares directly attacking this square (does not include 'discovered'/hidden attacks)
  const BB b_attackers = cBoard->pieces[WHITE][BISHOP] | cBoard->pieces[BLACK][BISHOP] | 
                         cBoard->pieces[WHITE][QUEEN]  | cBoard->pieces[BLACK][QUEEN];
  const BB r_attackers = cBoard->pieces[WHITE][ROOK]  | cBoard->pieces[BLACK][ROOK] | 
                         cBoard->pieces[WHITE][QUEEN] | cBoard->pieces[BLACK][QUEEN];

  BB temp_map = attack_map(p_board, to);
  BB temp_occ = Occupied();
  BB temp_pieces;

  // score += piece_value_at(sq_board, to);  
  pc_list[0] = piece_value_at(sq_board, to); // save the initial target piece to the victims list
  next_victim = piece_value_at(sq_board, from);

  clear_sq(from, temp_occ);
  // if the attacker was a pawn, bishop, rook, or queen, re-scan for sliding attacks after removing piece:
  type = piece_type_at(sq_board, from);
  if(type != KNIGHT && type != KING){
    if(type == PAWN || type == BISHOP || type == QUEEN) temp_map |= bishop_attacks(temp_occ, to) & b_attackers;
    if(type == PAWN || type == ROOK   || type == QUEEN) temp_map |= rook_attacks(temp_occ, to) & r_attackers;
  }
  temp_color^=1;

  int count = 1;
  for(temp_map &= temp_occ; temp_map; temp_map &= temp_occ){
    for(type = PAWN; type <= KING; type++){ // loop over piece types in order of value.
      temp_pieces = cBoard->pieces[temp_color][type] & temp_map;
      if(temp_pieces) break; // stop as soon as a match is found.
    }
    if(type > KING) break;  

    pc_list[count] = next_victim - pc_list[count-1];

    next_victim = piece_values[type];
    if(pc_list[count++] - next_victim > 0) break;

    temp_occ ^= (temp_pieces & -temp_pieces);  // merge the first set bit of temp_pieces into temp_occ
    if(type != KNIGHT && type != KING){
      if(type == PAWN || type == BISHOP || type == QUEEN) temp_map |= bishop_attacks(temp_occ, to) & b_attackers;
      if(type == ROOK || type == QUEEN) temp_map |= rook_attacks(temp_occ, to) & r_attackers;
    }
    temp_color^=1;
  }

  // if(count) printf("%d\n", count );
  while (--count){
    pc_list[count-1] = -max(-pc_list[count-1], pc_list[count]);
  } 


  return INT2NUM(pc_list[0]);

  // int alpha = -10000;
  // int beta = 10000;
  //   // iterative alpha-beta:
  //   if(score <= alpha) return INT2NUM(alpha);
  //   if(score < beta) beta = score;
  //   score += next_victim;

  //   if(score >= beta) return INT2NUM(beta);
  //   if(score > alpha) alpha = score;
  //   score -= next_victim;
  // return INT2NUM(score);


}

extern void Init_attack(){
  VALUE mod_chess = rb_define_module("Chess");
  VALUE cls_position = rb_define_class_under(mod_chess, "Position", rb_cObject);
  rb_define_method(cls_position, "side_in_check?", RUBY_METHOD_FUNC(is_in_check), 2);

  VALUE mod_search = rb_define_module_under(mod_chess, "Search");
  rb_define_module_function(mod_search, "static_exchange_evaluation", static_exchange_evaluation, 5);
}














