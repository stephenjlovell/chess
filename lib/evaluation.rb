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

module Chess
  module Evaluation # this module will contain all helper methods related to determining 
                    # the heuristic value of a given chess position.
      
    PST = {  # Piece Square Tables              # Piece Square Tables derived from the following sources:
      P: [  0,  0,  0,   0,   0,  0,  0,  0,    # http://www.youtube.com/watch?v=zSJF6jZ61w0,
           10, 10,  0, -10, -10,  0, 10, 10,    # http://www.bluefever.net/Downloads/CH56.zip
            5,  0,  0,   5,   5,  0,  0,  5,
            0,  0, 10,  20,  20, 10,  0,  0,
            5,  5,  5,  10,  10,  5,  5,  5,
           10, 10, 10,  20,  20, 10, 10, 10,
           20, 20, 20,  30,  30, 20, 20, 20,
            0,  0,  0,   0,   0,  0,  0,  0 ],  # base value of piece increases upon promotion


        #  A   B    C   D   E   F   G   H
      N: [ 0, -10,  0,  0,  0,  0, -10, 0,
           0,   0,  0,  5,  5,  0,   0, 0,
           0,   0, 10, 10, 10, 10,   0, 0,
           0,   0, 10, 20, 20, 10,   5, 0,
           5,  10, 15, 20, 20, 15,  10, 5,
           5,  10, 10, 20, 20, 10,  10, 5,
           0,   0,  5, 10, 10,  5,   0, 0,
           0,   0,  0,  0,  0,  0,   0, 0 ],

      B: [ 0,  0, -10,  0,  0, -10,  0, 0,
           0,  0,   0, 10, 10,   0,  0, 0,
           0,  0,  10, 15, 15,  10,  0, 0,
           0, 10,  15, 20, 20,  15, 10, 0,
           0, 10,  15, 20, 20,  15, 10, 0,
           0,  0,  10, 15, 15,  10,  0, 0,
           0,  0,   0, 10, 10,   0,  0, 0,
           0,  0,   0,  0,  0,   0,  0, 0 ],

      R: [  0,  0,  5, 10, 10,  10,  0,  0,
            0,  0,  5, 10, 10,  5,  0,  0,
            0,  0,  5, 10, 10,  5,  0,  0,
            0,  0,  5, 10, 10,  5,  0,  0,
            0,  0,  5, 10, 10,  5,  0,  0,
            0,  0,  5, 10, 10,  5,  0,  0,
           25, 25, 25, 25, 25, 25, 25, 25,
            0,  0,  5, 10, 10,  5,  0,  0 ],

      Q: [ 0, 0, 0, 0, 0, 0, 0, 0, # placeholder table
           0, 0, 0, 0, 0, 0, 0, 0,
           0, 0, 0, 0, 0, 0, 0, 0,
           0, 0, 0, 0, 0, 0, 0, 0,
           0, 0, 0, 0, 0, 0, 0, 0,
           0, 0, 0, 0, 0, 0, 0, 0,
           0, 0, 0, 0, 0, 0, 0, 0,
           0, 0, 0, 0, 0, 0, 0, 0 ],

      K: [ 0, 5, 15, 0, 5, 0, 15, 0, # placeholder table
           0, 0,  0, 0, 0, 0,  0, 0,
           0, 0,  0, 0, 0, 0,  0, 0,
           0, 0,  0, 0, 0, 0,  0, 0,
           0, 0,  0, 0, 0, 0,  0, 0,
           0, 0,  0, 0, 0, 0,  0, 0,
           0, 0,  0, 0, 0, 0,  0, 0,
           0, 0,  0, 0, 0, 0,  0, 0 ] 
    }

    MIRROR = [ 56, 57, 58, 59, 60, 61, 62, 63,
               48, 49, 50, 51, 52, 53, 54, 55,
               40, 41, 42, 43, 44, 45, 46, 47,
               32, 33, 34, 35, 36, 37, 38, 39,
               24, 25, 26, 27, 28, 29, 30, 31,
               16, 17, 18, 19, 20, 21, 22, 23,
                8,  9, 10, 11, 12, 13, 14, 15,
                0,  1,  2,  3,  4,  5,  6,  7 ]

    SQUARES = { a1: 0,  b1: 1,  c1: 2,  d1: 3,  e1: 4,  f1: 5,  g1: 6,  h1: 7,
                a2: 8,  b2: 9,  c2: 10, d2: 11, e2: 12, f2: 13, g2: 14, h2: 15,
                a3: 16, b3: 17, c3: 18, d3: 19, e3: 20, f3: 21, g3: 22, h3: 23,
                a4: 24, b4: 25, c4: 26, d4: 27, e4: 28, f4: 29, g4: 30, h4: 31,
                a5: 32, b5: 33, c5: 34, d5: 35, e5: 36, f5: 37, g5: 38, h5: 39,
                a6: 40, b6: 41, c6: 42, d6: 43, e6: 44, f6: 45, g6: 46, h6: 47,
                a7: 48, b7: 49, c7: 50, d7: 51, e7: 52, f7: 53, g7: 54, h7: 55,
                a8: 56, b8: 57, c8: 58, d8: 59, e8: 60, f8: 61, g8: 62, h8: 63 }


    def self.evaluate(position)
      $evaluation_calls += 1 
      net_material(position) + mobility(position)
    end

    def self.base_material(position, side)
      position.pieces[side].inject(0) { |total, (key, piece)| total += piece.class.value }
    end

    private

    def self.mobility(position)  # if possible, 
      # side, enemy = Chess::current_game.ai_player, Chess::current_game.opponent
      # if position.board.king_in_check?(position, side)
      #   -90
      # elsif position.board.king_in_check?(position, enemy)
      #   90
      # else
        0
      # end
    end

    def self.net_material(position) # net material value for side to move.
      side, enemy = Chess::current_game.ai_player, Chess::current_game.opponent
      # material(position, side) - material(position, enemy)
      position.material[side] - position.material[enemy]
    end

    def self.material(position, side) # =~ 1,040 at start
      position.pieces[side].inject(0) { |total, (key, piece)| total += adjusted_value(piece, key) }
    end

    def self.adjusted_value(piece, location, game_stage=nil)
      return piece.class.value + pst_value(piece, location)
    end

    def self.pst_value(piece, location, game_stage = nil)
      pst, sym = PST[piece.class.type], location.to_sym
      piece.color == :w ? pst[SQUARES[sym]] : pst[MIRROR[SQUARES[sym]]]
    end

  end
end 











