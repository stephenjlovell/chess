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

int knight_offsets[8] = { -17, -15, -10, -6, 6, 10, 15, 17 };
int bishop_offsets[4] = { -9, -7, 7, 9 };
int rook_offsets[4]   = { -8, -1, 1, 8 };
int king_offsets[8]   = { -9, -7, 7, 9, -8, -1, 1, 8 };
int pawn_offsets[4]   = { 9, 7, -9, -7 };

BB square_masks_on[64] = {0};
BB square_masks_off[64] = {0};
BB uni_mask = 0xffffffffffffffff;
BB empty_mask = 0x0;
BB row_masks[8] = {0};
BB column_masks[8] = {0};
BB pawn_masks[2][64] = { {0}, {0} };
BB knight_masks[64] = {0};
BB bishop_masks[64] = {0};
BB rook_masks[64] = {0};
BB queen_masks[64] = {0};
BB king_masks[64] = {0};
BB ray_masks[8][64] = { {0},{0},{0},{0},{0},{0},{0},{0} };


void setup_square_masks(){      // Precalculate the value of the bit representing each square.
  for(int i=0; i<64; i++){
    square_masks_on[i]  =  ((BB) 1 << i);
    printf("%lu\n", square_masks_on[i] );
    square_masks_off[i] = ~((BB) square_masks_on[i]);
    printf("%lu\n", square_masks_off[i] );
  }
}

void setup_pawn_masks(){
  int sq;
  for(int i=0; i<64; i++){
    if (i < 56){
      for(int j=0; j<2; j++){
        sq = i + pawn_offsets[j];
        if (manhattan_distance(sq, i)==2) pawn_masks[0][i] |= (1<<sq);     
      }
    }
    if (i > 7){
      for(int j=2; j<4; j++){
        sq = i + pawn_offsets[j];
        if (manhattan_distance(sq, i)==2) pawn_masks[1][i] |= (1<<sq);       
      }
    }
  }
}

void setup_knight_masks(){
  int sq;
  for(int i=0; i<64; i++){
    knight_masks[i] = 0;
    for(int j=0; j<8; j++){
      sq = i + knight_offsets[j];
      if (on_board(sq) && manhattan_distance(sq, i) == 3) knight_masks[i] |= (1<sq);
    }
  }
}

void setup_bishop_masks(){
  int square_key;
  int previous;
  int current;
  for(int i=0; i<64; i++){
    for(int j=0; j<4; j++){
      previous = i;
      current = i + bishop_offsets[j];
      while(on_board(current) && manhattan_distance(current, previous)==2){
        square_key = 1 << current;
        switch(square_key){
          case 7:
            ray_masks[NW][i] |= square_key;        
          case 9:
            ray_masks[NE][i] |= square_key;
          case -7:
            ray_masks[SE][i] |= square_key;
          case -9:
            ray_masks[SW][i] |= square_key;
        }
        previous = current;
        current += bishop_offsets[j];
      }
    }
    bishop_masks[i] = ray_masks[NW][i]|ray_masks[NE][i]|ray_masks[SE][i]|ray_masks[SW][i];
  }
}

void setup_rook_masks(){
  int square_key;
  int previous;
  int current;
  for(int i=0; i<64; i++){
    for(int j=0; j<4; j++){
      previous = i;
      current = i + rook_offsets[j];
      while(on_board(current) && manhattan_distance(current, previous)==1){
        square_key = 1 << current;
        switch(square_key){
          case 8:
            ray_masks[NORTH][i] |= square_key;        
          case -8:
            ray_masks[SOUTH][i] |= square_key;
          case 1:
            ray_masks[EAST][i] |= square_key;
          case -1:
            ray_masks[WEST][i] |= square_key;
        }
        previous = current;
        current += bishop_offsets[j];
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
    king_masks[i] = 0;
    for(int j=0; j<8; j++){
      sq = i + king_offsets[j];
      if (on_board(sq) && manhattan_distance(sq, i) <= 2) king_masks[i] |= (1<sq);
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

  setup_masks();

  printf("done.\n");
}







