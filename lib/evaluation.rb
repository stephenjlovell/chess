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
  module Evaluation

    # This module contains methods used to assess the heuristic value of a chess position.
    # RubyChess uses a very simplistic, low-cost evaluation function.  The evaluation score is based on 
    # three factors:
    
    #   1. Material balance - Sums the value of all pieces in play for each side.  A small bonus/penalty is applied
    #      based on the location of the piece.  Material balance is by far the largest component of the overall evaluation
    #      score.
    #   2. Mobility - If a side is in check, that side is in serious danger and must respond to the threat.
    #      A bonus/penalty equivalent to 3 pawns is applied depending on which side is in check.  The bonus is less than 
    #      one knight in order to prevent the AI from occasionally sacrificing major pieces merely to earn a temporary 
    #      evaulation bonus.
    #   3. King safety - The AI attempts to maximize the danger to the enemy king, and minimize the danger to its own king.
    #      This is approximated by awarding a bonus for each piece in play based on the value of the piece and its distance 
    #      to the opposing king.

    BASE_PST = {  # Piece Square Tables (PSTs) are used to provide a small positional bonus/penalty for controlling valuable       
                  # real estate on the board. Base PSTs are implemented relative to black side to move. 
                  # Base PSTs are taken from the ChessProgramming wiki: http://chessprogramming.wikispaces.com/CPW-Engine_eval_init
      # Pawn          
      P: [ 0,   0,   0,   0,   0,   0,   0,   0,
          -6,  -4,   1,   1,   1,   1,  -4,  -6,
          -6,  -4,   1,   2,   2,   1,  -4,  -6,
          -6,  -4,   2,   8,   8,   2,  -4,  -6,
          -6,  -4,   5,  10,  10,   5,  -4,  -6,
          -4,  -4,   1,   5,   5,   1,  -4,  -4,
          -6,  -4,   1, -24, -24,   1,  -4,  -6,
           0,   0,   0,   0,   0,   0,   0,   0 ],
      # Knight
      N: [ -8,  -8,  -8,  -8,  -8,  -8,  -8,  -8,
           -8,   0,   0,   0,   0,   0,   0,  -8,
           -8,   0,   4,   4,   4,   4,   0,  -8,
           -8,   0,   4,   8,   8,   4,   0,  -8,
           -8,   0,   4,   8,   8,   4,   0,  -8,
           -8,   0,   4,   4,   4,   4,   0,  -8,
           -8,   0,   1,   2,   2,   1,   0,  -8,
           -8,  -12, -8,  -8,  -8,  -8, -12,  -8 ],
      # Bishop
      B: [ -4,  -4,  -4,  -4,  -4,  -4,  -4,  -4,
           -4,   0,   0,   0,   0,   0,   0,  -4,
           -4,   0,   2,   4,   4,   2,   0,  -4,
           -4,   0,   4,   6,   6,   4,   0,  -4,
           -4,   0,   4,   6,   6,   4,   0,  -4,
           -4,   1,   2,   4,   4,   2,   1,  -4,
           -4,   2,   1,   1,   1,   1,   2,  -4,
           -4,  -4, -12,  -4,  -4, -12,  -4,  -4 ],
      # Rook
      R: [  5,   5,   5,   5,   5,   5,   5,   5,
           20,  20,  20,  20,  20,  20,  20,  20,
           -5,   0,   0,   0,   0,   0,   0,  -5,
           -5,   0,   0,   0,   0,   0,   0,  -5,
           -5,   0,   0,   0,   0,   0,   0,  -5,
           -5,   0,   0,   0,   0,   0,   0,  -5,
           -5,   0,   0,   0,   0,   0,   0,  -5,
            0,   0,   0,   2,   2,   0,   0,   0 ],
      # Queen
      Q: [  0,   0,   0,   0,   0,   0,   0,   0,
            0,   0,   1,   1,   1,   1,   0,   0,
            0,   0,   1,   2,   2,   1,   0,   0,
            0,   0,   2,   3,   3,   2,   0,   0,
            0,   0,   2,   3,   3,   2,   0,   0,
            0,   0,   1,   2,   2,   1,   0,   0,
            0,   0,   1,   1,   1,   1,   0,   0,
           -5,  -5,  -5,  -5,  -5,  -5,  -5,  -5 ] }

    KING_BASE = {
      # Used when side being evaluated is not in 'endgame'.
      false => [ -40, -40, -40, -40, -40, -40, -40, -40,   # In early game, encourage the king to stay on back 
                 -40, -40, -40, -40, -40, -40, -40, -40,   # row defended by friendly pieces.
                 -40, -40, -40, -40, -40, -40, -40, -40,
                 -40, -40, -40, -40, -40, -40, -40, -40,
                 -40, -40, -40, -40, -40, -40, -40, -40,
                 -40, -40, -40, -40, -40, -40, -40, -40,
                 -15, -15, -20, -20, -20, -20, -15, -15,
                   0,  20,  30, -30,   0, -20,  30,  20 ],
      # Used when side being evaluated is in 'endgame'.
      true => [ 0,  10,  20,  30,  30,  20,  10,   0,   # In end game (when few friendly pieces are available
               10,  20,  30,  40,  40,  30,  20,  10,   # to protect king), the king should move toward the center
               20,  30,  40,  50,  50,  40,  30,  20,   # and avoid getting trapped in corners.
               30,  40,  50,  60,  60,  50,  40,  30,
               30,  40,  50,  60,  60,  50,  40,  30,
               20,  30,  40,  50,  50,  40,  30,  20,
               10,  20,  30,  40,  40,  30,  20,  10,
                0,  10,  20,  30,  30,  20,  10,   0 ] }
    # Used to create a mirror image of the base PST.
    MIRROR = [ 56, 57, 58, 59, 60, 61, 62, 63,  
               48, 49, 50, 51, 52, 53, 54, 55,
               40, 41, 42, 43, 44, 45, 46, 47,
               32, 33, 34, 35, 36, 37, 38, 39,
               24, 25, 26, 27, 28, 29, 30, 31,
               16, 17, 18, 19, 20, 21, 22, 23,
                8,  9, 10, 11, 12, 13, 14, 15,
                0,  1,  2,  3,  4,  5,  6,  7 ]

    # Used to move from location object to 1-dimensional PST coordinate.
    SQUARES = { a1: 0,  b1: 1,  c1: 2,  d1: 3,  e1: 4,  f1: 5,  g1: 6,  h1: 7,
                a2: 8,  b2: 9,  c2: 10, d2: 11, e2: 12, f2: 13, g2: 14, h2: 15,
                a3: 16, b3: 17, c3: 18, d3: 19, e3: 20, f3: 21, g3: 22, h3: 23,
                a4: 24, b4: 25, c4: 26, d4: 27, e4: 28, f4: 29, g4: 30, h4: 31,
                a5: 32, b5: 33, c5: 34, d5: 35, e5: 36, f5: 37, g5: 38, h5: 39,
                a6: 40, b6: 41, c6: 42, d6: 43, e6: 44, f6: 45, g6: 46, h6: 47,
                a7: 48, b7: 49, c7: 50, d7: 51, e7: 52, f7: 53, g7: 54, h7: 55,
                a8: 56, b8: 57, c8: 58, d8: 59, e8: 60, f8: 61, g8: 62, h8: 63 }

    # Initialize Piece Square Tables for each color, endgame status, and piece type.
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

    # reverse the rows in the base PST 
    def self.mirror_table(arr)
      new_arr = Array.new(64, nil)
      (0..63).each { |i| new_arr[i] = arr[MIRROR[i]] }
      return new_arr
    end

    PST = create_pst

    EVAL_GRAIN = 1

    # The main evaluation method.  Calls methods for calculation of each evaluation component,
    # then divides the total eval score by EVAL_GRAIN to achieve the desired 'coarseness' of evaluation.
    def self.evaluate(position)
      $evaluation_calls += 1 
      ((net_material(position) + mobility(position) + net_king_safety(position))/EVAL_GRAIN).round.to_i
    end

    # Sums up the value of all pieces in play for the given side (without any positional bonuses/penalties).
    def self.base_material(position, side)
      position.pieces[side].inject(0) { |total, (key, piece)| total += piece.class.value }
    end

    private

    def self.net_king_safety(pos)
      king_safety(pos, pos.side_to_move) - king_safety(pos, pos.enemy)
    end

    # Award a bonus/penalty for each piece in play based on the value of the piece and its distance 
    # to the opposing king.
    def self.king_safety(pos, side, enemy_king_location=nil)
      sum = 0 
      enemy_king_location ||= pos.enemy_king_location
      pos.pieces[side].each do |loc, piece|
        sum += Tropism::get_bonus(piece, loc, enemy_king_location)
      end
      return sum
    end

    # Award a bonus/penalty depending on which side (if any) is in check.
    def self.mobility(position)  
      if position.in_check?
        -300
      elsif position.enemy_in_check?
        300
      else
        0
      end
    end

    def self.net_material(position) # net material value for side to move.
      (position.own_material - position.enemy_material)
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

  end
end 











