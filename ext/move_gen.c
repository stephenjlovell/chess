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


BB get_ray_attacks_reverse(BB occupied, enumDir dir, enumSq sq){
  BB ray = ray_masks[dir][sq];   // Get a bitmask for all ray moves along direction dir from origin square sq.
  BB blockers = occupied & ray;  // Find any pieces blocking movement along this ray.
  if (blockers){
    int first_blocker = msb(blockers);  // Get the bit index of the blocking piece closest to the origin square.
    ray &= (~ray_masks[dir][first_blocker]); // Slice off all squares after the first blocking piece and return
  }                                          // the remaining portion of the ray.
  return ray;
}

BB get_ray_attacks_forward(BB occupied, enumDir dir, enumSq sq){
  BB ray = ray_masks[dir][sq];   // Get a bitmask for all ray moves along direction dir from origin square sq.
  BB blockers = occupied & ray;  // Find any pieces blocking movement along this ray.
  if (blockers){
    int first_blocker = lsb(blockers);  // Get the bit index of the blocking piece closest to the origin square.
    ray &= (~ray_masks[dir][first_blocker]); // Slice off all squares after the first blocking piece and return
  }                                          // the remaining portion of the ray.
  return ray;
}

BB get_bishop_attacks(BB occupied, enumSq sq){
  BB attacks = 0;
  for(int i=2; i<4; i++){
    attacks |= get_ray_attacks_forward(occupied, i, sq);
  }
  for(int i=6; i<8; i++){
    attacks |= get_ray_attacks_reverse(occupied, i, sq);
  }
  return attacks;
}

BB get_rook_attacks(BB occupied, enumSq sq){
  BB attacks = 0;
  for(int i=0; i<2; i++){
    attacks |= get_ray_attacks_forward(occupied, i, sq);
  }
  for(int i=4; i<6; i++){
    attacks |= get_ray_attacks_reverse(occupied, i, sq);
  }
  return attacks;
}

BB get_queen_attacks(BB occupied, enumSq sq){
  return get_bishop_attacks(occupied, sq) | get_rook_attacks(occupied, sq);
}



void generate_non_captures(BOARD *position, enumSide side){
  BB occupied = position->all[WHITE] | position->all[BLACK];
  BB empty = ~occupied;
  int from, to;
  // generate regular knight moves
  BB pieces, attacks;

  // Knights
  for(pieces = position->knights[side]; pieces; clear(from, pieces)){
    from = furthest_forward(pieces, side);  // Locate each knight for the side to move.  
    attacks = knight_masks[from] & empty;

    // create Move object of strategy RegularMove for each target square.

  }

  // Bishops
  for(pieces = position->bishops[side]; pieces; clear(from, pieces)){
    from = furthest_forward(pieces, side);  // Locate each bishop for the side to move.  
    attacks = get_bishop_attacks(occupied, from) & empty;

    // create Move object of strategy RegularMove for each target square.

  }

  // Rooks
  for(pieces = position->bishops[side]; pieces; clear(from, pieces)){
    from = furthest_forward(pieces, side);  // Locate each rook for the side to move.  
    attacks = get_rook_attacks(occupied, from) & empty;

    // create Move object of strategy RegularMove for each target square.

  }

  // Queens
  for(pieces = position->bishops[side]; pieces; clear(from, pieces)){
    from = furthest_forward(pieces, side);  // Locate each queen for the side to move.  
    attacks = get_queen_attacks(occupied, from) & empty;

    // create Move object of strategy RegularMove for each target square.

  }

}


// Pawn moves, king moves, and castle moves require special treatment... others do not. 
// Simply separating them into captures and non-captures will suffice.







void Init_move_gen(){

}












