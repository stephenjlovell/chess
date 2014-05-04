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

#include "eval.h"

int non_king_value;
int endgame_value;

void setup_eval_constants(){
  non_king_value = piece_values[PAWN]*8 + piece_values[KNIGHT]*2 + piece_values[BISHOP]*2 +
                   piece_values[ROOK]*2 + piece_values[QUEEN];
  endgame_value =  piece_values[KING]   - (non_king_value/4);
}

// Only base material is incrementally updated.

static VALUE net_material(VALUE self, VALUE pc_board, VALUE color){
  BRD *cBoard = get_cBoard(pc_board);  
  int c = SYM2COLOR(color);
  int e = c^1;
  int sq, placement = 0;
  BB b;
  return INT2NUM(adjusted_material(c, cBoard)-adjusted_material(e, cBoard));
}

static VALUE net_placement(VALUE self, VALUE pc_board, VALUE color){
  BRD *cBoard = get_cBoard(pc_board);  
  int c = SYM2COLOR(color);
  int e = c^1;
  int sq, placement = 0;
  BB b;
  return INT2NUM(adjusted_placement(c, cBoard)-adjusted_placement(e, cBoard));
}

static int adjusted_placement(int c, BRD *cBoard){
  int sq, placement = 0;
  BB b, enemy_king_b = cBoard->pieces[c^1][KING];

  if(enemy_king_b){
    int enemy_king_sq = lsb(enemy_king_b);
    for(int type = PAWN; type < QUEEN; type++){
      for(b = cBoard->pieces[c][type]; b; clear_sq(sq, b)){
        sq = furthest_forward(c, b);
        placement += (main_pst[c][type][sq] + tropism_bonus[sq][enemy_king_sq][type]);
      }
    }
    for(b = cBoard->pieces[c][KING]; b; clear_sq(sq, b)){
      sq = furthest_forward(c, b);
      placement += king_pst[c][in_endgame(c)][sq];
    }
  } else {
    for(int type = PAWN; type < QUEEN; type++){
      for(b = cBoard->pieces[c][type]; b; clear_sq(sq, b)){
        sq = furthest_forward(c, b);
        placement += main_pst[c][type][sq];
      }
    }
    for(b = cBoard->pieces[c][KING]; b; clear_sq(sq, b)){
      sq = furthest_forward(c, b);
      placement += king_pst[c][in_endgame(c)][sq];
    }
  }
  return cBoard->material[c] + placement;
}



static int adjusted_material(int c, BRD *cBoard){
  int sq, placement = 0;
  BB b;

  for(int type = PAWN; type < QUEEN; type++){
    for(b = cBoard->pieces[c][type]; b; clear_sq(sq, b)){
      sq = furthest_forward(c, b);
      placement += main_pst[c][type][sq];
    }
  }
  for(b = cBoard->pieces[c][KING]; b; clear_sq(sq, b)){
    sq = furthest_forward(c, b);
    placement += king_pst[c][in_endgame(c)][sq];
  }
  return cBoard->material[c] + placement;
}


static VALUE evaluate_material(VALUE self, VALUE pc_board, VALUE color){
  BRD *cBoard = get_cBoard(pc_board);  
  int c = SYM2COLOR(color);
  int sq, placement = 0;
  BB b;

  for(int type = PAWN; type < QUEEN; type++){
    b = cBoard->pieces[c][type];
    for(b = cBoard->pieces[c][type]; b; clear_sq(sq, b)){
      sq = furthest_forward(c, b);
      placement += main_pst[c][type][sq];
    }
  }
  for(b = cBoard->pieces[c][KING]; b; clear_sq(sq, b)){
    sq = furthest_forward(c, b);
    placement += king_pst[c][in_endgame(c)][sq];
  }
  return INT2NUM(cBoard->material[c] + placement);
}


static int main_pst[2][5][64] = {
  { // Black
    // Pawn
   {  0,  0,  0,  0,  0,  0,  0,  0, 
     -1,  1,  1,  1,  1,  1,  1, -1, 
     -2,  0,  1,  2,  2,  1,  0, -2, 
     -3, -1,  2, 10, 10,  2, -1, -3, 
     -4, -2,  4, 14, 14,  4, -2, -4, 
     -5, -3,  0,  9,  9,  0, -3, -5, 
     -6, -4,  0,-20,-20,  0, -4, -6, 
      0,  0,  0,  0,  0,  0,  0,  0 },
  // Knight
   { -8, -8, -6, -6, -6, -6, -8, -8, 
     -8,  0,  0,  0,  0,  0,  0, -8, 
     -6,  0,  4,  4,  4,  4,  0, -6, 
     -6,  0,  4,  8,  8,  4,  0, -6, 
     -6,  0,  4,  8,  8,  4,  0, -6, 
     -6,  0,  4,  4,  4,  4,  0, -6, 
     -8,  0,  1,  2,  2,  1,  0, -8, 
    -10,-12, -6, -6, -6, -6,-12,-10 },
  // Bishop
   { -3, -3, -3, -3, -3, -3, -3, -3, 
     -3,  0,  0,  0,  0,  0,  0, -3, 
     -3,  0,  2,  4,  4,  2,  0, -3, 
     -3,  0,  4,  5,  5,  4,  0, -3, 
     -3,  0,  4,  5,  5,  4,  0, -3, 
     -3,  1,  2,  4,  4,  2,  1, -3, 
     -3,  2,  1,  1,  1,  1,  2, -3, 
     -3, -3,-10, -3, -3,-10, -3, -3 },
  // Rook
  {   4,  4,  4,  4,  4,  4,  4,  4,
     16, 16, 16, 16, 16, 16, 16, 16,
     -4,  0,  0,  0,  0,  0,  0, -4,
     -4,  0,  0,  0,  0,  0,  0, -4,
     -4,  0,  0,  0,  0,  0,  0, -4,
     -4,  0,  0,  0,  0,  0,  0, -4,
     -4,  0,  0,  0,  0,  0,  0, -4,
      0,  0,  0,  2,  2,  0,  0,  0 },
  // Queen
   {  0,  0,  0,  1,  1,  0,  0,  0, 
      0,  0,  1,  2,  2,  1,  0,  0, 
      0,  1,  2,  2,  2,  2,  1,  0, 
      0,  1,  2,  3,  3,  2,  1,  0, 
      0,  1,  2,  3,  3,  2,  1,  0, 
      0,  1,  1,  2,  2,  1,  1,  0, 
      0,  0,  1,  1,  1,  1,  0,  0, 
     -6, -6, -6, -6, -6, -6, -6, -6 },
}, // White
{  // Pawn
    { 0,  0,  0,  0,  0,  0,  0,  0, 
     -6, -4,  0,-20,-20,  0, -4, -6, 
     -5, -3,  0,  9,  9,  0, -3, -5,
     -4, -2,  4, 14, 14,  4, -2, -4, 
     -3, -1,  2, 10, 10,  2, -1, -3, 
     -2,  0,  1,  2,  2,  1,  0, -2, 
     -1,  1,  1,  1,  1,  1,  1, -1, 
      0,  0,  0,  0,  0,  0,  0,  0 },
  // Knight
   {-10,-12, -6, -6, -6, -6,-12,-10, 
     -8,  0,  1,  2,  2,  1,  0, -8, 
     -6,  0,  4,  4,  4,  4,  0, -6, 
     -6,  0,  4,  8,  8,  4,  0, -6, 
     -6,  0,  4,  8,  8,  4,  0, -6,
     -6,  0,  4,  4,  4,  4,  0, -6, 
     -8,  0,  0,  0,  0,  0,  0, -8, 
     -8, -8, -6, -6, -6, -6, -8, -8 },
    // Bishop
   { -3, -3,-10, -3, -3,-10, -3, -3, 
     -3,  2,  1,  1,  1,  1,  2, -3, 
     -3,  1,  2,  4,  4,  2,  1, -3, 
     -3,  0,  4,  5,  5,  4,  0, -3, 
     -3,  0,  4,  5,  5,  4,  0, -3, 
     -3,  0,  2,  4,  4,  2,  0, -3, 
     -3,  0,  0,  0,  0,  0,  0, -3, 
     -3, -3, -3, -3, -3, -3, -3, -3 },
    // Rook
   {  0,  0,  0,  2,  2,  0,  0,  0, 
     -4,  0,  0,  0,  0,  0,  0, -4, 
     -4,  0,  0,  0,  0,  0,  0, -4, 
     -4,  0,  0,  0,  0,  0,  0, -4, 
     -4,  0,  0,  0,  0,  0,  0, -4, 
     -4,  0,  0,  0,  0,  0,  0, -4, 
     16, 16, 16, 16, 16, 16, 16, 16, 
      4,  4,  4,  4,  4,  4,  4,  4 },
      // Queen
   { -6, -6, -6, -6, -6, -6, -6, -6,
      0,  0,  1,  1,  1,  1,  0,  0, 
      0,  1,  1,  2,  2,  1,  1,  0, 
      0,  1,  2,  3,  3,  2,  1,  0, 
      0,  1,  2,  3,  3,  2,  1,  0, 
      0,  1,  2,  2,  2,  2,  1,  0, 
      0,  0,  1,  2,  2,  1,  0,  0, 
      0,  0,  0,  1,  1,  0,  0,  0 }
  }
};

static int king_pst[2][2][64] = { 
 { // Black // False
  { -52,-50,-50,-50,-50,-50,-50,-52,   // In early game, encourage the king to stay on back 
    -50,-48,-48,-48,-48,-48,-48,-50,   // row defended by friendly pieces.
    -48,-46,-46,-46,-46,-46,-46,-48,
    -46,-44,-44,-44,-44,-44,-44,-46,
    -44,-42,-42,-42,-42,-42,-42,-44,
    -42,-40,-40,-40,-40,-40,-40,-42,
    -16,-15,-20,-20,-20,-20,-15,-16,
      0, 20, 30,-30,  0,-20, 30, 20 },
    { // True
    -30,-20,-10,  0,  0,-10,-20,-30,     // In end game (when few friendly pieces are available
    -20,-10,  0, 10, 10,  0,-10,-20,     // to protect king), the king should move toward the center
    -10,  0, 10, 20, 20, 10,  0,-10,     // and avoid getting trapped in corners.
      0, 10, 20, 30, 30, 20, 10,  0,
      0, 10, 20, 30, 30, 20, 10,  0,
    -10,  0, 10, 20, 20, 10,  0,-10,
    -20,-10,  0, 10, 10,  0,-10,-20,
    -30,-20,-10,  0,  0,-10,-20,-30 }
  },
  { // White // False
   {  0, 20, 30,-30,  0,-20, 30, 20, 
    -16,-15,-20,-20,-20,-20,-15,-16, 
    -42,-40,-40,-40,-40,-40,-40,-42, 
    -44,-42,-42,-42,-42,-42,-42,-44, 
    -46,-44,-44,-44,-44,-44,-44,-46, 
    -48,-46,-46,-46,-46,-46,-46,-48, 
    -50,-48,-48,-48,-48,-48,-48,-50, 
    -52,-50,-50,-50,-50,-50,-50,-52 },
    { // True
    -30,-20,-10,  0,  0,-10,-20,-30, 
    -20,-10,  0, 10, 10,  0,-10,-20, 
    -10,  0, 10, 20, 20, 10,  0,-10, 
      0, 10, 20, 30, 30, 20, 10,  0, 
      0, 10, 20, 30, 30, 20, 10,  0, 
    -10,  0, 10, 20, 20, 10,  0,-10,
    -20,-10,  0, 10, 10,  0,-10,-20, 
    -30,-20,-10,  0,  0,-10,-20,-30 }
  }
};

extern void Init_eval(){
  printf("  -Loading eval extension...");
  setup_eval_constants();

  VALUE mod_chess = rb_define_module("Chess");
  VALUE mod_eval = rb_define_module_under(mod_chess, "Evaluation");

  rb_define_module_function(mod_eval, "evaluate_material", evaluate_material, 2);
  rb_define_module_function(mod_eval, "net_material", net_material, 2);
  rb_define_module_function(mod_eval, "net_placement", net_placement, 2);

  printf("done.\n");
}





