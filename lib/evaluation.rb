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
  module Evaluation # this module provides a heuristic value for a given chess position.

    BASE_PST = {  # Piece Square Tables for black.           

      P: [ 0,   0,   0,   0,   0,   0,   0,   0,
          -6,  -4,   1,   1,   1,   1,  -4,  -6,
          -6,  -4,   1,   2,   2,   1,  -4,  -6,
          -6,  -4,   2,   8,   8,   2,  -4,  -6,
          -6,  -4,   5,  10,  10,   5,  -4,  -6,
          -4,  -4,   1,   5,   5,   1,  -4,  -4,
          -6,  -4,   1, -24, -24,   1,  -4,  -6,
           0,   0,   0,   0,   0,   0,   0,   0 ],


      N: [ -8,  -8,  -8,  -8,  -8,  -8,  -8,  -8,
           -8,   0,   0,   0,   0,   0,   0,  -8,
           -8,   0,   4,   4,   4,   4,   0,  -8,
           -8,   0,   4,   8,   8,   4,   0,  -8,
           -8,   0,   4,   8,   8,   4,   0,  -8,
           -8,   0,   4,   4,   4,   4,   0,  -8,
           -8,   0,   1,   2,   2,   1,   0,  -8,
           -8,  -12, -8,  -8,  -8,  -8, -12,  -8 ],


      B: [ -4,  -4,  -4,  -4,  -4,  -4,  -4,  -4,
           -4,   0,   0,   0,   0,   0,   0,  -4,
           -4,   0,   2,   4,   4,   2,   0,  -4,
           -4,   0,   4,   6,   6,   4,   0,  -4,
           -4,   0,   4,   6,   6,   4,   0,  -4,
           -4,   1,   2,   4,   4,   2,   1,  -4,
           -4,   2,   1,   1,   1,   1,   2,  -4,
           -4,  -4, -12,  -4,  -4, -12,  -4,  -4 ],


      R: [  5,   5,   5,   5,   5,   5,   5,   5,
           20,  20,  20,  20,  20,  20,  20,  20,
           -5,   0,   0,   0,   0,   0,   0,  -5,
           -5,   0,   0,   0,   0,   0,   0,  -5,
           -5,   0,   0,   0,   0,   0,   0,  -5,
           -5,   0,   0,   0,   0,   0,   0,  -5,
           -5,   0,   0,   0,   0,   0,   0,  -5,
            0,   0,   0,   2,   2,   0,   0,   0 ],


      Q: [  0,   0,   0,   0,   0,   0,   0,   0,
            0,   0,   1,   1,   1,   1,   0,   0,
            0,   0,   1,   2,   2,   1,   0,   0,
            0,   0,   2,   3,   3,   2,   0,   0,
            0,   0,   2,   3,   3,   2,   0,   0,
            0,   0,   1,   2,   2,   1,   0,   0,
            0,   0,   1,   1,   1,   1,   0,   0,
           -5,  -5,  -5,  -5,  -5,  -5,  -5,  -5 ]

    }

    KING_BASE = {
      false => [ -40, -40, -40, -40, -40, -40, -40, -40,   # false game
                 -40, -40, -40, -40, -40, -40, -40, -40,
                 -40, -40, -40, -40, -40, -40, -40, -40,
                 -40, -40, -40, -40, -40, -40, -40, -40,
                 -40, -40, -40, -40, -40, -40, -40, -40,
                 -40, -40, -40, -40, -40, -40, -40, -40,
                 -15, -15, -20, -20, -20, -20, -15, -15,
                   0,  20,  30, -30,   0, -20,  30,  20 ],

      true => [ 0,  10,  20,  30,  30,  20,  10,   0,   # true game 
               10,  20,  30,  40,  40,  30,  20,  10,
               20,  30,  40,  50,  50,  40,  30,  20,
               30,  40,  50,  60,  60,  50,  40,  30,
               30,  40,  50,  60,  60,  50,  40,  30,
               20,  30,  40,  50,  50,  40,  30,  20,
               10,  20,  30,  40,  40,  30,  20,  10,
                0,  10,  20,  30,  30,  20,  10,   0 ] }


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


    def self.create_pst
      pst = { w: { false => {}, true => {} }, b: { false => {}, true => {} } }
      BASE_PST.each do |type, arr|
        pst[:b][false][type] = arr
        pst[:b][true][type] = arr
      end
      pst[:b][false][:K] = KING_BASE[false]
      pst[:b][true][:K] = KING_BASE[true]

      BASE_PST.each do |type, arr|
        mirror = mirror_table(arr)
        pst[:w][false][type] = mirror
        pst[:w][true][type] = mirror   
      end
      pst[:w][false][:K] = mirror_table(KING_BASE[false])
      pst[:w][true][:K] = mirror_table(KING_BASE[true])
      return pst
    end

    def self.mirror_table(arr)
      new_arr = Array.new(64, nil)
      (0..63).each { |i| new_arr[i] = arr[MIRROR[i]] }
      return new_arr
    end

    PST = create_pst

    EVAL_GRAIN = 2

    def self.evaluate(position)
      $evaluation_calls += 1 
      net_material(position) + mobility(position)
    end

    def self.base_material(position, side)
      position.pieces[side].inject(0) { |total, (key, piece)| total += piece.class.value }
    end

    private

    def self.mobility(position)  
      side, enemy = Chess::current_game.ai_player, Chess::current_game.opponent
      if position.board.king_in_check?(position, side)
        -90
      elsif position.board.king_in_check?(position, enemy)
        90
      else
        0
      end
    end

    def self.net_material(position) # net material value for side to move.
      (position.own_material - position.enemy_material) / EVAL_GRAIN
    end

    def self.material(position, side, endgame=nil) # =~ 1,040 at start
      position.pieces[side].inject(0) do |total, (key, piece)| 
        total += adjusted_value(position, piece, key, endgame)
      end
    end

    def self.adjusted_value(position, piece, loc, endgame=nil)
      piece.class.value + pst_value(position, piece, loc, endgame)
    end    

    def self.pst_value(position, piece, loc, endgame=nil)
      endgame = position.endgame?(piece.color) if endgame.nil?
      type, sq = piece.class.type, SQUARES[loc.to_sym]
      PST[piece.color][endgame][type][sq]
    end


    # def self.adjusted_value(piece, location, game_stage=nil)

    #   return piece.class.value + pst_value(piece, location)
    
    # end

    # def self.pst_value(piece, location, game_stage = nil)
    #   pst, sym = PST[piece.class.type], location.to_sym

    #   # piece.color == :w ? pst[SQUARES[sym]] : pst[MIRROR[SQUARES[sym]]]
    #   piece.color == :w ? pst[MIRROR[SQUARES[sym]]] : pst[SQUARES[sym]]
    # end

  end
end 











