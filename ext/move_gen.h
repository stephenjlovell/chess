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

#ifndef MOVE_GEN_H
#define MOVE_GEN_H


BB get_quiet_moves_reverse(BB occupied, enumDir dir, enumSq sq);

BB get_quiet_moves_forward(BB occupied, enumDir dir, enumSq sq);

BB get_all_moves_reverse(BB occupied, enumDir dir, enumSq sq);

BB get_all_moves_forward(BB occupied, enumDir dir, enumSq sq);

BB get_bishop_attacks(BB occupied, enumSq sq);


BB get_rook_attacks(BB occupied, enumSq sq);

BB get_queen_attacks(BB occupied, enumSq sq);

void Init_move_gen();


#endif





