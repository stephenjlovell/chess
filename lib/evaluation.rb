#-----------------------------------------------------------------------------------
# Copyright (c) 2013 Stephen J. Lovell
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#-----------------------------------------------------------------------------------

module Application
  module Evaluation
    # this module will contain all helper methods related to determining the heuristic value of
    # a given chess position.

    # Piece-Square Tables
    PST = { 

      wP:[],
      bP:[],

      wR:[],
      bR:[],

      wN:[],
      bN:[],

      wB:[],
      wB:[],

      wQ:[],
      bQ:[],

      wK:[],
      bK:[],

    }
# Pawn
0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 ,
10, 10, 0, -10, -10, 0, 10, 10,
5, 0, 0, 5, 5, 0, 0, 5,
0, 0, 10, 20, 20, 10, 0, 0,
5, 5, 5, 10, 10, 5, 5, 5,
10, 10, 10, 20, 20, 10, 10, 10,
20, 20, 20, 30, 30, 20, 20, 20,
0, 0, 0, 0, 0, 0, 0, 0 

# Knight
0, -10, 0, 0 , 0 , 0 , -10 , 0 ,
0, 0 , 0 , 5 , 5 , 0 , 0 , 0 ,
0, 0 , 10  , 10  , 10  , 10  , 0 , 0 ,
0, 0 , 10  , 20  , 20  , 10  , 5 , 0 ,
5, 10  , 15  , 20  , 20  , 15  , 10  , 5 ,
5, 10  , 10  , 20  , 20  , 10  , 10  , 5 ,
0, 0 , 5 , 10  , 10  , 5 , 0 , 0 ,
0, 0 , 0 , 0 , 0 , 0 , 0 , 0   

const int BishopTable[64] = {
0 , 0 , -10 , 0 , 0 , -10 , 0 , 0 ,
0 , 0 , 0 , 10  , 10  , 0 , 0 , 0 ,
0 , 0 , 10  , 15  , 15  , 10  , 0 , 0 ,
0 , 10  , 15  , 20  , 20  , 15  , 10  , 0 ,
0 , 10  , 15  , 20  , 20  , 15  , 10  , 0 ,
0 , 0 , 10  , 15  , 15  , 10  , 0 , 0 ,
0 , 0 , 0 , 10  , 10  , 0 , 0 , 0 ,
0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 
};

const int RookTable[64] = {
0 , 0 , 5 , 10  , 10  , 5 , 0 , 0 ,
0 , 0 , 5 , 10  , 10  , 5 , 0 , 0 ,
0 , 0 , 5 , 10  , 10  , 5 , 0 , 0 ,
0 , 0 , 5 , 10  , 10  , 5 , 0 , 0 ,
0 , 0 , 5 , 10  , 10  , 5 , 0 , 0 ,
0 , 0 , 5 , 10  , 10  , 5 , 0 , 0 ,
25  , 25  , 25  , 25  , 25  , 25  , 25  , 25  ,
0 , 0 , 5 , 10  , 10  , 5 , 0 , 0   
};

const int Mirror64[64] = {
56  , 57  , 58  , 59  , 60  , 61  , 62  , 63  ,
48  , 49  , 50  , 51  , 52  , 53  , 54  , 55  ,
40  , 41  , 42  , 43  , 44  , 45  , 46  , 47  ,
32  , 33  , 34  , 35  , 36  , 37  , 38  , 39  ,
24  , 25  , 26  , 27  , 28  , 29  , 30  , 31  ,
16  , 17  , 18  , 19  , 20  , 21  , 22  , 23  ,
8 , 9 , 10  , 11  , 12  , 13  , 14  , 15  ,
0 , 1 , 2 , 3 , 4 , 5 , 6 , 7
};






    def self.evaluate(position) # return heuristic value of specified position.
      friend = position.side_to_move
      enemy = friend == :w ? :b : :w
      return net_raw_material(position,friend, enemy)
    end

    def self.net_raw_material(position, friend, enemy) # net material value for side to move.
      raw_material(position, friend) - raw_material(position, enemy)
    end

    def self.raw_material(position, side) # =~ 1,040 at start
      position.pieces[side].inject(0) { |total, (key, piece)| total += piece.class.value }  
    end

  end
end 











