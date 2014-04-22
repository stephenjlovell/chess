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

// #include "shared.h"
#include "bitboard.h"

static VALUE mod_chess;

int knight_offsets[8] = { -17, -15, -10, -6, 6, 10, 15, 17 };
int bishop_offsets[4] = { 7, 9, -7, -9 };
int rook_offsets[4]   = { 8, 1, -8, -1 };
int king_offsets[8]   = { -9, -7, 7, 9, -8, -1, 1, 8 };

int pawn_attack_offsets[4]   = { 9, 7, -9, -7 };
int pawn_advance_offsets[4] = {8, 16, -8, -16};
int pawn_enpassant_offsets[2] = {1, -1};

BB uni_mask = 0xffffffffffffffff;
BB empty_mask = 0x0;

BB square_masks_on[64] = {0};
BB square_masks_off[64] = {0};

BB row_masks[8] = {0};
BB column_masks[8] = {0};
BB ray_masks[8][64] = { {0},{0},{0},{0},{0},{0},{0},{0} };

BB pawn_attack_masks[2][64] = { {0}, {0} };
BB pawn_from_squares[2][64] = { {0}, {0} };
BB pawn_double_from_squares[2][64] = { {0}, {0} };

BB pawn_left_attack_from_squares[2][64] = { {0}, {0} };
BB pawn_right_attack_from_squares[2][64] = { {0}, {0} };
BB pawn_enp_masks[64] = {0};

BB knight_masks[64] = {0};
BB bishop_masks[64] = {0};
BB rook_masks[64] = {0};
BB queen_masks[64] = {0};
BB king_masks[64] = {0};


void setup_square_masks(){      // Precalculate the value of the bit representing each square.
  for(int i=0; i<64; i++){
    square_masks_on[i]  =  ((BB) 1 << i);
    square_masks_off[i] = ~(square_masks_on[i]);
  }
}

void setup_pawn_masks(){
  int sq;
  for(int i=0; i<64; i++){
    if(row(i)==3 || row(i)==4){
      if (column(i)!=7) pawn_enp_masks[i] |= sq_mask_on(i+1);
      if (column(i)!=0) pawn_enp_masks[i] |= sq_mask_on(i-1);
    }
    if (i < 56){
      pawn_from_squares[BLACK][i] = (i+8);
      if (row(i)==4) pawn_double_from_squares[BLACK][i] = (i+16);
      if (column(i)!=7) pawn_left_attack_from_squares[BLACK][i] = (i+9);
      if (column(i)!=0) pawn_right_attack_from_squares[BLACK][i] = (i+7);

      for(int j=0; j<2; j++){
        sq = i + pawn_attack_offsets[j];
        if (manhattan_distance(sq, i)==2) pawn_attack_masks[WHITE][i] |= sq_mask_on(sq);  
      }
    }
    if (i > 7){
      pawn_from_squares[WHITE][i] = (i-8);
      if (row(i)==3) pawn_double_from_squares[WHITE][i] = (i-16);
      if (column(i)!=7) pawn_left_attack_from_squares[WHITE][i] = (i-7);
      if (column(i)!=0) pawn_right_attack_from_squares[WHITE][i] = (i-9);

      for(int j=2; j<4; j++){
        sq = i + pawn_attack_offsets[j];
        if (manhattan_distance(sq, i)==2) pawn_attack_masks[BLACK][i] |= sq_mask_on(sq); 
      }
    }
  }
}

void setup_knight_masks(){
  int sq;
  for(int i=0; i<64; i++){
    for(int j=0; j<8; j++){
      sq = i + knight_offsets[j];
      if (on_board(sq) && manhattan_distance(sq, i) == 3) knight_masks[i] |= sq_mask_on(sq);
    }
  }
}

void setup_bishop_masks(){
  int previous, current, offset;
  for(int i=0; i<64; i++){
    for(int j=0; j<4; j++){
      previous = i;
      offset = bishop_offsets[j];
      current = i + offset;
      while(on_board(current) && manhattan_distance(current, previous)==2){
        ray_masks[j][i] |= sq_mask_on(current);
        previous = current;
        current += offset;
      }
    }
    bishop_masks[i] = ray_masks[NW][i]|ray_masks[NE][i]|ray_masks[SE][i]|ray_masks[SW][i];
  }
}

void setup_rook_masks(){
  int previous, current, offset;
  for(int i=0; i<64; i++){
    for(int j=0; j<4; j++){
      previous = i;
      offset = rook_offsets[j];
      current = i + offset;
      while(on_board(current) && manhattan_distance(current, previous)==1){
        ray_masks[j+4][i] |= sq_mask_on(current);
        previous = current;
        current += offset;
      }
    }
    rook_masks[i] = ray_masks[NORTH][i]|ray_masks[SOUTH][i]|ray_masks[EAST][i]|ray_masks[WEST][i];
  }
}

void setup_queen_masks(){
  for(int i=0; i<64; i++) queen_masks[i] = (bishop_masks[i] | rook_masks[i]);
}

void setup_king_masks(){
  int sq;
  for(int i=0; i<64; i++){
    for(int j=0; j<8; j++){
      sq = i + king_offsets[j];
      if (on_board(sq) && manhattan_distance(sq, i) <= 2) king_masks[i] |= sq_mask_on(sq);
    }
  }
}

void setup_row_masks(){
  row_masks[0] = 0xff;    // set the first row to binary 11111111, or 255.
  for(int i=1; i<8; i++){
    row_masks[i] = (row_masks[i-1] << 8);  // create the remaining rows by shifting the previous
  }                                        // row up by 8 squares.
}

void setup_column_masks(){
  column_masks[0] = 1;
  for(int i=0; i<8; i++) column_masks[0] |= (column_masks[0]<<8);  // set the first column
  for(int i=1; i<8; i++){
    column_masks[i] = (column_masks[i-1]<<1);  // create the remaining columns by transposing the 
  }                                           // previous column rightward.
}


void setup_masks(){ 
  setup_square_masks();

  setup_pawn_masks();     // For each square, calculate bitboard attack maps showing 
  setup_knight_masks();   // the squares to which the given piece type may move. These are
  setup_bishop_masks();   // used as bitmasks during move generation to find pseudolegal moves.
  setup_rook_masks();
  setup_queen_masks();     
  setup_king_masks();

  setup_row_masks();      // Create bitboard masks for each row and column.
  setup_column_masks();
}

extern void Init_bitboard(){
  printf("  -Loading bitboard extension...");

  mod_chess = rb_define_module("Chess");

  setup_masks();

  printf("done.\n");
}







