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



VALUE get_knight_non_captures(VALUE self, VALUE knights, VALUE occupied){
  occupied = NUM2ULONG(occupied);
  BB empty = ~occupied;
  BB moves;
  VALUE arr = rb_ary_new();
  int from, to, packed;

  for(knights = NUM2ULONG(knights); knights; clear_sq(from, knights)){
    from = lsb(knights); // Locate each knight for the side to move.  
    for( moves = (knight_masks[from] & empty); moves; clear_sq(to, moves)){ // generate to squares
      to = lsb(moves);
      packed = from & (to<<6); // pack each to/from pair into an integer 
      rb_ary_push(arr, ULONG2NUM(packed));
    }
  }
  return arr;  // send an array of integers representing to/from pairs to Ruby.
}

VALUE get_knight_captures(VALUE self, VALUE knights, VALUE enemy){
  enemy = NUM2ULONG(enemy);
  BB moves;
  VALUE arr = rb_ary_new();
  int from, to, packed;

  for(knights = NUM2ULONG(knights); knights; clear_sq(from, knights)){
    from = lsb(knights); // Locate each knight for the side to move.  
    for(moves = (knight_masks[from] & enemy); moves; clear_sq(to, moves)){ // generate to squares
      to = lsb(moves);
      packed = from & (to<<6); // pack each to/from pair into an integer 
      rb_ary_push(arr, ULONG2NUM(packed));
    }
  }
  return arr;  // send an array of integers representing to/from pairs to Ruby.
}

VALUE get_bishop_non_captures(VALUE self, VALUE bishops, VALUE occupied){
  occupied = NUM2ULONG(occupied);
  BB empty = ~occupied;
  BB moves;
  VALUE arr = rb_ary_new();
  int from, to, packed;

  for(bishops = NUM2ULONG(bishops); bishops; clear_sq(from, bishops)){
    from = lsb(bishops); // Locate each bishop for the side to move.  
    for(moves = (get_bishop_attacks(occupied, from) & empty); moves; clear_sq(to, moves)){ // generate to squares
      to = lsb(moves);
      packed = from & (to<<6); // pack each to/from pair into an integer 
      rb_ary_push(arr, ULONG2NUM(packed));
    }
  }
  return arr;  // send an array of integers representing to/from pairs to Ruby.
}

VALUE get_bishop_captures(VALUE self, VALUE bishops, VALUE occupied, VALUE enemy){
  occupied = NUM2ULONG(occupied);
  enemy = NUM2ULONG(enemy);
  BB empty = ~occupied;
  BB moves;
  VALUE arr = rb_ary_new();
  int from, to, packed;

  for(bishops = NUM2ULONG(bishops); bishops; clear_sq(from, bishops)){
    from = lsb(bishops); // Locate each bishop for the side to move.  
    for(moves = (get_bishop_attacks(occupied, from) & enemy); moves; clear_sq(to, moves)){ // generate to squares
      to = lsb(moves);
      packed = from & (to<<6); // pack each to/from pair into an integer 
      rb_ary_push(arr, ULONG2NUM(packed));
    }
  }
  return arr;  // send an array of integers representing to/from pairs to Ruby.
}


VALUE get_rook_non_captures(VALUE self, VALUE rooks, VALUE occupied){
  occupied = NUM2ULONG(occupied);
  BB empty = ~occupied;
  BB moves;
  VALUE arr = rb_ary_new();
  int from, to, packed;

  for(rooks = NUM2ULONG(rooks); rooks; clear_sq(from, rooks)){
    from = lsb(rooks); // Locate each bishop for the side to move.  
    for(moves = (get_rook_attacks(occupied, from) & empty); moves; clear_sq(to, moves)){ // generate to squares
      to = lsb(moves);
      packed = from & (to<<6); // pack each to/from pair into an integer 
      rb_ary_push(arr, ULONG2NUM(packed));
    }
  }
  return arr;  // send an array of integers representing to/from pairs to Ruby.
}

VALUE get_rook_captures(VALUE self, VALUE rooks, VALUE occupied, VALUE enemy){
  occupied = NUM2ULONG(occupied);
  enemy = NUM2ULONG(enemy);
  BB empty = ~occupied;
  BB moves;
  VALUE arr = rb_ary_new();
  int from, to, packed;

  for(rooks = NUM2ULONG(rooks); rooks; clear_sq(from, rooks)){
    from = lsb(rooks); // Locate each bishop for the side to move.  
    for(moves = (get_rook_attacks(occupied, from) & enemy); moves; clear_sq(to, moves)){ // generate to squares
      to = lsb(moves);
      packed = from & (to<<6); // pack each to/from pair into an integer 
      rb_ary_push(arr, ULONG2NUM(packed));
    }
  }
  return arr;  // send an array of integers representing to/from pairs to Ruby.
}


VALUE get_queen_non_captures(VALUE self, VALUE queens, VALUE occupied){
  occupied = NUM2ULONG(occupied);
  BB empty = ~occupied;
  BB moves;
  VALUE arr = rb_ary_new();
  int from, to, packed;

  for(queens = NUM2ULONG(queens); queens; clear_sq(from, queens)){
    from = lsb(queens); // Locate each bishop for the side to move.  
    for(moves = (get_queen_attacks(occupied, from) & empty); moves; clear_sq(to, moves)){ // generate to squares
      to = lsb(moves);
      packed = from & (to<<6); // pack each to/from pair into an integer 
      rb_ary_push(arr, ULONG2NUM(packed));
    }
  }
  return arr;  // send an array of integers representing to/from pairs to Ruby.
}

VALUE get_queen_captures(VALUE self, VALUE queens, VALUE occupied, VALUE enemy){
  occupied = NUM2ULONG(occupied);
  enemy = NUM2ULONG(enemy);
  BB empty = ~occupied;
  BB moves;
  VALUE arr = rb_ary_new();
  int from, to, packed;

  for(queens = NUM2ULONG(queens); queens; clear_sq(from, queens)){
    from = lsb(queens); // Locate each bishop for the side to move.  
    for(moves = (get_queen_attacks(occupied, from) & enemy); moves; clear_sq(to, moves)){ // generate to squares
      to = lsb(moves);
      packed = from & (to<<6); // pack each to/from pair into an integer 
      rb_ary_push(arr, ULONG2NUM(packed));
    }
  }
  return arr;  // send an array of integers representing to/from pairs to Ruby.
}

VALUE get_king_non_captures(VALUE self, VALUE kings, VALUE occupied){
  occupied = NUM2ULONG(occupied);
  BB empty = ~occupied;
  BB moves;
  VALUE arr = rb_ary_new();
  int from, to, packed;

  from = lsb(kings); // Locate each knight for the side to move.  
  for( moves = (king_masks[from] & empty); moves; clear_sq(to, moves)){ // generate to squares
    to = lsb(moves);
    packed = from & (to<<6); // pack each to/from pair into an integer 
    rb_ary_push(arr, ULONG2NUM(packed));
  }
  return arr;  // send an array of integers representing to/from pairs to Ruby.
}

VALUE get_king_captures(VALUE self, VALUE kings, VALUE enemy){
  enemy = NUM2ULONG(enemy);
  BB moves;
  VALUE arr = rb_ary_new();
  int from, to, packed;

  from = lsb(kings); // Locate each knight for the side to move.  
  for(moves = (king_masks[from] & enemy); moves; clear_sq(to, moves)){ // generate to squares
    to = lsb(moves);
    packed = from & (to<<6); // pack each to/from pair into an integer 
    rb_ary_push(arr, ULONG2NUM(packed));
  }
  return arr;  // send an array of integers representing to/from pairs to Ruby.
}


extern void Init_move_gen(){
  printf("  -Loading move_gen extension...");

  VALUE mod_chess  = rb_define_module("Chess");
  VALUE mod_pieces = rb_define_module_under(mod_chess, "Pieces");

  VALUE cls_piece = rb_define_class_under(mod_pieces, "Piece", rb_cObject);
  
  VALUE cls_pawn   = rb_define_class_under(mod_pieces, "Pawn", cls_piece);
  VALUE cls_knight = rb_define_class_under(mod_pieces, "Knight", cls_piece);
  VALUE cls_bishop = rb_define_class_under(mod_pieces, "Bishop", cls_piece);
  VALUE cls_rook   = rb_define_class_under(mod_pieces, "Rook", cls_piece);
  VALUE cls_queen  = rb_define_class_under(mod_pieces, "Queen", cls_piece);
  VALUE cls_king   = rb_define_class_under(mod_pieces, "King", cls_piece);

  // rb_define_singleton_method(cls_pawn, "get_pawn_non_captures", RUBY_METHOD_FUNC(get_pawn_non_captures), 2);
  // rb_define_singleton_method(cls_pawn, "get_pawn_captures", RUBY_METHOD_FUNC(get_pawn_captures), 2);  

  rb_define_singleton_method(cls_knight, "get_knight_non_captures", RUBY_METHOD_FUNC(get_knight_non_captures), 2);
  rb_define_singleton_method(cls_knight, "get_knight_captures", RUBY_METHOD_FUNC(get_knight_captures), 2);

  rb_define_singleton_method(cls_bishop, "get_bishop_non_captures", RUBY_METHOD_FUNC(get_bishop_non_captures), 2);
  rb_define_singleton_method(cls_bishop, "get_bishop_captures", RUBY_METHOD_FUNC(get_bishop_captures), 3);

  rb_define_singleton_method(cls_rook, "get_bishop_non_captures", RUBY_METHOD_FUNC(get_rook_non_captures), 2);
  rb_define_singleton_method(cls_rook, "get_bishop_captures", RUBY_METHOD_FUNC(get_rook_captures), 3);

  rb_define_singleton_method(cls_queen, "get_queen_non_captures", RUBY_METHOD_FUNC(get_queen_non_captures), 2);
  rb_define_singleton_method(cls_queen, "get_queen_captures", RUBY_METHOD_FUNC(get_queen_captures), 3);

  rb_define_singleton_method(cls_king, "get_king_non_captures", RUBY_METHOD_FUNC(get_king_non_captures), 2);
  rb_define_singleton_method(cls_king, "get_king_captures", RUBY_METHOD_FUNC(get_king_captures), 3);


  printf("done.\n");
}












