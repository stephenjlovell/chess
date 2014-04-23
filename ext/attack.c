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

BB attack_map(enumSq sq){
  BB attacks = 0;
  BB occ = Occupied();
  // Pawns
  attacks |= (pawn_attack_masks[BLACK][sq] & cBoard->pieces[WHITE][PAWN]) |
             (pawn_attack_masks[WHITE][sq] & cBoard->pieces[BLACK][PAWN]);
  // Knights
  attacks |= (knight_masks[sq] & (cBoard->pieces[WHITE][KNIGHT]|cBoard->pieces[BLACK][KNIGHT]));
  // Bishops and Queens
  BB bishop_attackers = cBoard->pieces[WHITE][BISHOP] | cBoard->pieces[BLACK][BISHOP] | 
                        cBoard->pieces[WHITE][QUEEN]  | cBoard->pieces[BLACK][QUEEN];
  attacks |= (bishop_attacks(occ, sq) & bishop_attackers);
  // Rooks and Queens
  BB rook_attackers = cBoard->pieces[WHITE][ROOK]  | cBoard->pieces[BLACK][ROOK] | 
                      cBoard->pieces[WHITE][QUEEN] | cBoard->pieces[BLACK][QUEEN];
  attacks |= (rook_attacks(occ, sq) & rook_attackers);
  // Kings
  attacks |= (king_masks[sq] & (cBoard->pieces[WHITE][KING]|cBoard->pieces[BLACK][KING]));
  return attacks;
}

int is_attacked(enumSq sq){
  BB occ = Occupied();
  // Pawns
  if((pawn_attack_masks[BLACK][sq] & cBoard->pieces[WHITE][PAWN]) |
     (pawn_attack_masks[WHITE][sq] & cBoard->pieces[BLACK][PAWN])) return 1; 
  // Knights
  if(knight_masks[sq] & (cBoard->pieces[WHITE][KNIGHT]|cBoard->pieces[BLACK][KNIGHT])) return 1;
  // Bishops
  BB bishop_attackers = cBoard->pieces[WHITE][BISHOP] | cBoard->pieces[BLACK][BISHOP] | 
                        cBoard->pieces[WHITE][QUEEN]  | cBoard->pieces[BLACK][QUEEN];
  if(bishop_attacks(occ, sq) & bishop_attackers) return 1;
  // Rooks
  BB rook_attackers = cBoard->pieces[WHITE][ROOK]  | cBoard->pieces[BLACK][ROOK] | 
                      cBoard->pieces[WHITE][QUEEN] | cBoard->pieces[BLACK][QUEEN];
  if(rook_attacks(occ, sq) & rook_attackers) return 1;
  // Kings
  if(king_masks[sq] & (cBoard->pieces[WHITE][KING]|cBoard->pieces[BLACK][KING])) return 1;
  return 0;
}

VALUE static_exchange_evaluation(VALUE square, VALUE side_to_move){
  assert(cBoard != NULL);

  int sq = (NUM2INT(square));
  int c = SYM2COLOR(side_to_move);
  int e = (c^1);

  // get a map of all squares directly attacking this square (does not include 'discovered'/hidden attacks)
  BB map = attack_map(sq);

  BB own_map = (map & cBoard->occupied[c]);
  BB enemy_map = (map & cBoard->occupied[e]);




  // Add any hidden attacker to the map
  return Qnil;
}

static int place_next_attacker(BB *side_map, int side_color){
  int target_value = 0;

  // Locate the cheapest attacking piece currently available.

  // After a sliding piece attacks the target square, check behind that piece for any hidden sliding piece attackers.

  // add the hidden attacker (if any) to side_map; it's now available to attack.


  return target_value; // return the value of the piece placed.
}  





extern void Init_attack(){

}














