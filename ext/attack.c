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

BB attack_map(BRD *cBoard, enumSq sq){
  BB attacks = 0;
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

BB color_attack_map(BRD *cBoard, enumSq sq, int c, int e){
  BB attacks = 0;
  BB occ = Occupied();
  // Pawns
  attacks |= pawn_attack_masks[e][sq] & cBoard->pieces[c][PAWN];
  // Knights
  attacks |= knight_masks[sq] & cBoard->pieces[c][KNIGHT];
  // Bishops and Queens
  BB b_attackers = cBoard->pieces[c][BISHOP] | cBoard->pieces[c][QUEEN];
  attacks |= bishop_attacks(occ, sq) & b_attackers;
  // Rooks and Queens
  BB r_attackers = cBoard->pieces[c][ROOK] | cBoard->pieces[c][QUEEN];
  attacks |= rook_attacks(occ, sq) & r_attackers;
  // Kings
  attacks |= king_masks[sq] & cBoard->pieces[c][KING];
  return attacks;
}

int is_attacked_by(BRD *cBoard, enumSq sq, int attacker, int defender){
  BB occ = Occupied();
  // Pawns
  if(pawn_attack_masks[defender][sq] & cBoard->pieces[attacker][PAWN]) return 1; 
  // Knights
  if(knight_masks[sq] & (cBoard->pieces[attacker][KNIGHT])) return 1;
  // Bishops and Queens
  if(bishop_attacks(occ, sq) & (cBoard->pieces[attacker][BISHOP]|cBoard->pieces[attacker][QUEEN])) return 1;
  // Rooks and Queens
  if(rook_attacks(occ, sq) & (cBoard->pieces[attacker][ROOK]|cBoard->pieces[attacker][QUEEN])) return 1;
  // Kings
  if(king_masks[sq] & (cBoard->pieces[attacker][KING])) return 1;
  return 0;
}

// Determines if a piece is blocking a ray attack to its king, and cannot move off this ray
// without placing its king in check.
// 1. Find the displacement vector between the piece at sq and its own king and determine if it
//    lies along a valid ray attack.  If the vector is a valid ray attack:
// 2. Scan toward the king to see if there are any other pieces blocking this route to the king.
// 3. Scan in the opposite direction to see detect any potential threats along this ray.
BB is_pinned(BRD* cBoard, int sq, int c, int e){
  BB occ = Occupied();
  BB threat = 0, guarded_king = 0;
  int dir = directions[sq][furthest_forward(c, cBoard->pieces[c][KING])]; //get direction toward king
  switch(dir){    // NW, NE, SE, SW, NORTH, EAST, SOUTH, WEST, INVALID
    case NW:
    case NE:
      threat = scan_down(occ, dir+2, sq) & (cBoard->pieces[e][BISHOP]|cBoard->pieces[e][QUEEN]);
      guarded_king = scan_up(occ, dir, sq) & (cBoard->pieces[c][KING]);
      break;
    case SE: 
    case SW:
      threat = scan_up(occ, dir-2, sq) & (cBoard->pieces[e][BISHOP]|cBoard->pieces[e][QUEEN]);
      guarded_king = scan_down(occ, dir, sq) & (cBoard->pieces[c][KING]);
      break;
    case NORTH:
    case EAST:
      threat = scan_down(occ, dir+2, sq) & (cBoard->pieces[e][ROOK]|cBoard->pieces[e][QUEEN]);
      guarded_king = scan_up(occ, dir, sq) & (cBoard->pieces[c][KING]);
      break;
    case SOUTH: 
    case WEST:
      threat = scan_up(occ, dir-2, sq) & (cBoard->pieces[e][ROOK]|cBoard->pieces[e][QUEEN]);
      guarded_king = scan_down(occ, dir, sq) & (cBoard->pieces[c][KING]);
      break;
    case INVALID: return 0; break;
  }
  return threat & guarded_king;
}

// The Static Exchange Evaluation (SEE) heuristic provides a way to determine if a capture 
// is a 'winning' or 'losing' capture.
// 1. When a capture results in an exchange of pieces by both sides, SEE is used to determine the 
//    net gain/loss in material for the side initiating the exchange.
// 2. SEE scoring of moves is used for move ordering of captures at critical nodes.
// 3. During quiescence search, SEE is used to prune losing captures. This provides a very low-risk
//    way of reducing the size of the q-search without impacting playing strength.
extern int get_see(BRD *cBoard, int from, int to, int c, VALUE sq_board){
  int next_victim, type, last_type;
  int temp_color = c^1;
  int score = 0;
  // get initial map of all squares directly attacking this square (does not include 'discovered'/hidden attacks)
  const BB b_attackers = cBoard->pieces[WHITE][BISHOP] | cBoard->pieces[BLACK][BISHOP] | 
                         cBoard->pieces[WHITE][QUEEN]  | cBoard->pieces[BLACK][QUEEN];
  const BB r_attackers = cBoard->pieces[WHITE][ROOK]   | cBoard->pieces[BLACK][ROOK]   | 
                         cBoard->pieces[WHITE][QUEEN]  | cBoard->pieces[BLACK][QUEEN];

  BB temp_map = attack_map(cBoard, to);
  BB temp_occ = Occupied();
  BB temp_pieces;

  int piece_list[20];
  int count = 1;

  // before entering the main loop, perform each step once for the initial attacking piece.  This ensures that the
  // moved piece is the first to capture.

  piece_list[0] = piece_value_at(sq_board, to);

  next_victim = piece_value_at(sq_board, from);
  type = piece_type_at(sq_board, from);
  clear_sq(from, temp_occ);
  if(type != KNIGHT && type != KING){ // if the attacker was a pawn, bishop, rook, or queen, re-scan for hidden attacks:
    if(type == PAWN || type == BISHOP || type == QUEEN) temp_map |= bishop_attacks(temp_occ, to) & b_attackers;
    if(type == PAWN || type == ROOK   || type == QUEEN) temp_map |= rook_attacks(temp_occ, to) & r_attackers;
  }
  last_type = type;

  for(temp_map &= temp_occ; temp_map; temp_map &= temp_occ){
    for(type = PAWN; type <= KING; type++){ // loop over piece types in order of value.
      temp_pieces = cBoard->pieces[temp_color][type] & temp_map;
      if(temp_pieces) break; // stop as soon as a match is found.
    }
    if(type > KING) break;

    piece_list[count] = -piece_list[count-1] + next_victim;
    next_victim = piece_values[type];
    if(piece_list[count++]- next_victim > 0) break;

    if(last_type == KING) break;

    temp_occ ^= (temp_pieces & -temp_pieces);  // merge the first set bit of temp_pieces into temp_occ
    if(type != KNIGHT && type != KING){
      if(type == PAWN || type == BISHOP || type == QUEEN) temp_map |= (bishop_attacks(temp_occ, to) & b_attackers);
      if(type == ROOK || type == QUEEN) temp_map |= (rook_attacks(temp_occ, to) & r_attackers);
    }
    temp_color^=1;
    last_type = type;
  }

  // detect kings that are not at the very end of the move list

  while(--count) piece_list[count-1] = -max(-piece_list[count-1], piece_list[count]);

  return piece_list[0];
}


// Alpha-beta variant of SEE algorithm.
extern int get_see_ab(BRD *cBoard, int from, int to, int c, VALUE sq_board){
  int next_victim, type, last_type;
  int temp_color = c^1;
  int score = 0;
  // get initial map of all squares directly attacking this square (does not include 'discovered'/hidden attacks)
  const BB b_attackers = cBoard->pieces[WHITE][BISHOP] | cBoard->pieces[BLACK][BISHOP] | 
                         cBoard->pieces[WHITE][QUEEN]  | cBoard->pieces[BLACK][QUEEN];
  const BB r_attackers = cBoard->pieces[WHITE][ROOK]   | cBoard->pieces[BLACK][ROOK]   | 
                         cBoard->pieces[WHITE][QUEEN]  | cBoard->pieces[BLACK][QUEEN];

  BB temp_map = attack_map(cBoard, to);
  BB temp_occ = Occupied();
  int alpha = -1000000;
  int beta  =  1000000;  // beta set to 0 initially since attacking side can simply choose not to attack at all.
  BB temp_pieces;

  // before entering the main loop, perform each step once for the initial attacking piece.  This ensures that the
  // moved piece is the first to capture.

  beta = score;
  score += piece_value_at(sq_board, to);
  // if(score <= alpha) return alpha;
  if (score < beta){
    beta = score;
    // printf("beta is now:");
    // printf("%d\n", beta);
  } 

  next_victim = piece_value_at(sq_board, from);
  type = piece_type_at(sq_board, from);
  clear_sq(from, temp_occ);
  if(type != KNIGHT && type != KING){ // if the attacker was a pawn, bishop, rook, or queen, re-scan for hidden attacks:
    if(type == PAWN || type == BISHOP || type == QUEEN) temp_map |= bishop_attacks(temp_occ, to) & b_attackers;
    if(type == PAWN || type == ROOK   || type == QUEEN) temp_map |= rook_attacks(temp_occ, to) & r_attackers;
  }
  last_type = type;

  for(temp_map &= temp_occ; temp_map; temp_map &= temp_occ){
    for(type = PAWN; type <= KING; type++){ // loop over piece types in order of value.
      temp_pieces = cBoard->pieces[temp_color][type] & temp_map;
      if(temp_pieces) break; // stop as soon as a match is found.
    }
    if(type > KING) break;

    if(c == temp_color){    // iterative alpha-beta:
      if(last_type == KING) return alpha;
      score += next_victim;
      if(score <= alpha) return alpha;
      if(score < beta) {
        beta = score;
        // printf("beta is now:");
        // printf("%d\n", beta);
      } 
      // if(last_type == KING) return alpha;
    } else {
      if(last_type == KING) return beta;
      score -= next_victim;
      if(score >= beta) return beta;
      if(score > alpha) { 
        alpha = score;
        // printf("alpha is now:");
        // printf("%d\n", alpha);
      }
      // if(last_type == KING) return beta;
    }

    next_victim = piece_values[type];
    last_type = type;
    temp_occ ^= (temp_pieces & -temp_pieces);  // merge the first set bit of temp_pieces with temp_occ
    if(type != KNIGHT && type != KING){
      if(type == PAWN || type == BISHOP || type == QUEEN) temp_map |= (bishop_attacks(temp_occ, to) & b_attackers);
      if(type == ROOK || type == QUEEN) temp_map |= (rook_attacks(temp_occ, to) & r_attackers);
    }
    temp_color^=1;
  }
  // printf("no bound found. returning score: ");
  // printf("%d\n", score);
  return score;
}

// Ruby interface

static VALUE is_in_check(VALUE self, VALUE p_board, VALUE side_to_move){
  BRD *cBoard = get_cBoard(p_board);
  int c = SYM2COLOR(side_to_move);
  int e = c^1;
  if(!cBoard->pieces[c][KING]) return Qtrue;
  return (is_attacked_by(cBoard, furthest_forward(c, cBoard->pieces[c][KING]), e, c) ? Qtrue : Qfalse);
}

static VALUE move_evades_check(VALUE self, VALUE p_board, VALUE sq_board, VALUE from, VALUE to, VALUE color){
  BRD *cBoard = get_cBoard(p_board);
  int c = SYM2COLOR(color);
  int e = c^1;
  int f = NUM2INT(from), t = NUM2INT(to);
  int check;

  int piece = NUM2INT(rb_ary_entry(sq_board, f));  // ?
  int captured_piece = NUM2INT(rb_ary_entry(sq_board, t));

  if(!cBoard->pieces[c][KING]) return Qfalse;

  BB delta = (sq_mask_on(t)|sq_mask_on(f));
  cBoard->pieces[c][piece_type(piece)] ^= delta;
  cBoard->occupied[c] ^= delta;

  if(captured_piece){
    clear_sq(t, cBoard->pieces[e][piece_type(captured_piece)]);
    clear_sq(t, cBoard->occupied[e]);
    // determine if in check
    check = is_attacked_by(cBoard, furthest_forward(c, cBoard->pieces[c][KING]), e, c);
    add_sq(t, cBoard->pieces[e][piece_type(captured_piece)]);
    add_sq(t, cBoard->occupied[e]);
  } else {
    // determine if in check
    check = is_attacked_by(cBoard, furthest_forward(c, cBoard->pieces[c][KING]), e, c);
  }
  cBoard->pieces[c][piece_type(piece)] ^= delta;
  cBoard->occupied[c] ^= delta;

  return (check ? Qfalse : Qtrue);
}

// Determines if a move will put the enemy's king in check.
static VALUE move_gives_check(VALUE self, VALUE p_board, VALUE sq_board, VALUE from, VALUE to, 
                              VALUE color, VALUE promoted_piece){
  BRD *cBoard = get_cBoard(p_board);
  int c = SYM2COLOR(color);
  int e = c^1;
  int f = NUM2INT(from), t = NUM2INT(to);
  int check;

  int piece = NUM2INT(rb_ary_entry(sq_board, f));  // ?
  int captured_piece = NUM2INT(rb_ary_entry(sq_board, t));

  if(!cBoard->pieces[e][KING]) return Qtrue;

  BB delta = (sq_mask_on(t)|sq_mask_on(f));
  cBoard->occupied[c] ^= delta;
  if(promoted_piece != Qnil){
    clear_sq(f, cBoard->pieces[c][piece_type(piece)]);
    add_sq(t, cBoard->pieces[c][piece_type(NUM2INT(promoted_piece))]);
    if(captured_piece){
      clear_sq(t, cBoard->pieces[e][piece_type(captured_piece)]);
      clear_sq(t, cBoard->occupied[e]);
      // determine if in check
      check = is_attacked_by(cBoard, furthest_forward(e, cBoard->pieces[e][KING]), c, e);
      add_sq(t, cBoard->pieces[e][piece_type(captured_piece)]);
      add_sq(t, cBoard->occupied[e]);
    } else { // determine if in check
      check = is_attacked_by(cBoard, furthest_forward(e, cBoard->pieces[e][KING]), c, e);
    }
    add_sq(f, cBoard->pieces[c][piece_type(piece)]);
    clear_sq(t, cBoard->pieces[c][piece_type(NUM2INT(promoted_piece))]);

  } else {
    cBoard->pieces[c][piece_type(piece)] ^= delta;
    if(captured_piece){
      clear_sq(t, cBoard->pieces[e][piece_type(captured_piece)]);
      clear_sq(t, cBoard->occupied[e]);
      // determine if in check
      check = is_attacked_by(cBoard, furthest_forward(e, cBoard->pieces[e][KING]), c, e);
      add_sq(t, cBoard->pieces[e][piece_type(captured_piece)]);
      add_sq(t, cBoard->occupied[e]);
    } else { // determine if in check
      check = is_attacked_by(cBoard, furthest_forward(e, cBoard->pieces[e][KING]), c, e);
    }
    cBoard->pieces[c][piece_type(piece)] ^= delta;
  }
  cBoard->occupied[c] ^= delta;

  return check ? Qtrue : Qfalse;
}


static VALUE is_pseudolegal_move_legal(VALUE self, VALUE p_board, VALUE piece, VALUE f, VALUE t, VALUE color){
  int c = SYM2COLOR(color);
  int e = c^1;
  BRD *cBoard = get_cBoard(p_board);
  if(piece_type(NUM2INT(piece)) == KING){ // determine if the to square is attacked by an enemy piece.
    return is_attacked_by(cBoard, NUM2INT(t), e, c) ? Qfalse : Qtrue;  // castle moves are pre-checked for legality
  } else { // determine if the piece being moved is pinned on the king and can't move without putting king at risk.
    BB pinned = is_pinned(cBoard, NUM2INT(f), c, e);
    return pinned && (~pinned & sq_mask_on(NUM2INT(t))) ? Qfalse : Qtrue;
  }
}


static VALUE static_exchange_evaluation(VALUE self, VALUE p_board, VALUE from, VALUE to, VALUE side_to_move, VALUE sq_board){
  return INT2NUM(get_see(get_cBoard(p_board), NUM2INT(from), NUM2INT(to), SYM2COLOR(side_to_move), sq_board));
}


extern void Init_attack(){
  VALUE mod_chess = rb_define_module("Chess");
  VALUE cls_position = rb_define_class_under(mod_chess, "Position", rb_cObject);
  rb_define_method(cls_position, "side_in_check?", RUBY_METHOD_FUNC(is_in_check), 2);
  rb_define_method(cls_position, "move_is_legal?", RUBY_METHOD_FUNC(move_evades_check), 5);
  rb_define_method(cls_position, "move_gives_check?", RUBY_METHOD_FUNC(move_gives_check), 6);
  rb_define_method(cls_position, "move_avoids_check?", RUBY_METHOD_FUNC(is_pseudolegal_move_legal), 5);

  VALUE mod_search = rb_define_module_under(mod_chess, "Search");
  rb_define_module_function(mod_search, "static_exchange_evaluation", static_exchange_evaluation, 5);
}



