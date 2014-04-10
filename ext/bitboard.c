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

#include "ruby.h"
#include <stdio.h>

typedef unsigned long BB;

BB UNI_MASK = 0xffffffffffffffff;
BB EMPTY_MASK = 0x0;


BB square_keys[64];

BB pawn_masks[2][64];
BB knight_masks[64];
BB bishop_masks[64];
BB rook_masks[64];
BB queen_masks[64];
BB king_masks[64];


BB ray_north_masks[64];
BB ray_ne_masks[64];
BB ray_east_masks[64];
BB ray_se_masks[64];
BB ray_south_masks[64];
BB ray_sw_masks[64];
BB ray_west_masks[64];
BB ray_nw_masks[64];

typedef enum { NORTH, NE, EAST, SE, SOUTH, SW, WEST, NW } RayDirection;

// BB *ray_masks[8];

const int KNIGHT_OFFSETS[8] = { -17, -15, -10, -6, 6, 10, 15, 17 };
const int BISHOP_OFFSETS[4] = { -9, -7, 7, 9 };
const int ROOK_OFFSETS[4]   = { -8, -1, 1, 8 };
const int KING_OFFSETS[8]   = { -9, -7, 7, 9, -8, -1, 1, 8 };
const int PAWN_OFFSETS[4]   = { 9, 7, -9, -7 };

#define on_board(sq) ((sq&0xffffffffffffffff) != 0)
#define column(sq) (sq >> 3)
#define row(sq) (sq & 7)
#define manhattan_distance(from, to) (abs(row(from)-row(to))+(abs(column(from)-column(to))))

void setup_knight_masks(){
  int sq;
  for(int i=0; i<64; i++){
    knight_masks[i] = 0;
    for(int j=0; j<8; j++){
      sq = i + KNIGHT_OFFSETS[j];
      if (on_board(sq) && manhattan_distance(sq, i) == 3) knight_masks[i] |= (1<sq);
    }
  }
}

void setup_king_masks(){
  int sq;
  for(int i=0; i<64; i++){
    king_masks[i] = 0;
    for(int j=0; j<8; j++){
      sq = i + KING_OFFSETS[j];
      if (on_board(sq) && manhattan_distance(sq, i) <= 2) king_masks[i] |= (1<sq);
    }
  }
}

void setup_pawn_masks(){
  int sq;
  for(int i=0; i<64; i++){
    if (i < 56){
      for(int j=0; j<2; j++){
        sq = i + PAWN_OFFSETS[j];
        if (manhattan_distance(sq, i)==2) pawn_masks[0][i] |= (1<<sq);     
      }
    }
    if (i > 7){
      for(int j=2; j<4; j++){
        sq = i + PAWN_OFFSETS[j];
        if (manhattan_distance(sq, i)==2) pawn_masks[1][i] |= (1<<sq);       
      }
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
      current = i + BISHOP_OFFSETS[j];
      while(on_board(current) && manhattan_distance(current, previous)==2){
        square_key = 1 << current;
        switch(square_key){
          case 7:
            ray_nw_masks[i] |= square_key;        
          case 9:
            ray_ne_masks[i] |= square_key;
          case -7:
            ray_se_masks[i] |= square_key;
          case -9:
            ray_sw_masks[i] |= square_key;
        }
        previous = current;
        current += BISHOP_OFFSETS[j];
      }
    }
    bishop_masks[i] = ray_nw_masks[i]|ray_ne_masks[i]|ray_se_masks[i]|ray_sw_masks[i];
  }
}

void setup_rook_masks(){
  int square_key;
  int previous;
  int current;
  for(int i=0; i<64; i++){
    for(int j=0; j<4; j++){
      previous = i;
      current = i + ROOK_OFFSETS[j];
      while(on_board(current) && manhattan_distance(current, previous)==1){
        square_key = 1 << current;
        switch(square_key){
          case 8:
            ray_north_masks[i] |= square_key;        
          case -8:
            ray_south_masks[i] |= square_key;
          case 1:
            ray_east_masks[i] |= square_key;
          case -1:
            ray_west_masks[i] |= square_key;
        }
        previous = current;
        current += BISHOP_OFFSETS[j];
      }
    }
    rook_masks[i] = ray_north_masks[i]|ray_south_masks[i]|ray_east_masks[i]|ray_west_masks[i];
  }
}

void setup_masks(){
  setup_pawn_masks();
  setup_knight_masks();
  setup_bishop_masks();
  setup_rook_masks();
  setup_king_masks();
}

void Init_bitboard(){
  printf("Ruby and C are good friends.\n");
}










