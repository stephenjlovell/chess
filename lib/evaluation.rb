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
    #      A bonus/penalty equivalent to 3.5 pawns is applied depending on which side is in check.
    #   3. King safety - The AI attempts to maximize the danger to the enemy king, and minimize the danger to its own king.
    #      This is approximated by awarding a bonus for each piece in play based on the value of the piece and its distance 
    #      to the opposing king.

    BASE_PST = {  # Piece Square Tables (PSTs) are used to provide a small positional bonus/penalty for controlling valuable       
                  # real estate on the board. Base PSTs are implemented relative to black side to move. 
      # Pawn          
      P: [ 0,  0,  0,  0,  0,  0,  0,  0, 
          -1,  1,  1,  1,  1,  1,  1, -1, 
          -2,  0,  1,  2,  2,  1,  0, -2, 
          -3, -1,  2, 10, 10,  2, -1, -3, 
          -4, -2,  4, 14, 14,  4, -2, -4, 
          -5, -3,  0,  9,  9,  0, -3, -5, 
          -6, -4,  0,-20,-20,  0, -4, -6, 
           0,  0,  0,  0,  0,  0,  0,  0 ],
      # Knight
      N: [  -8, -8, -6, -6, -6, -6, -8, -8, 
            -8,  0,  0,  0,  0,  0,  0, -8, 
            -6,  0,  4,  4,  4,  4,  0, -6, 
            -6,  0,  4,  8,  8,  4,  0, -6, 
            -6,  0,  4,  8,  8,  4,  0, -6, 
            -6,  0,  4,  4,  4,  4,  0, -6, 
            -8,  0,  1,  2,  2,  1,  0, -8, 
           -10,-12, -6, -6, -6, -6,-12,-10 ],
      # Bishop
      B: [ -3, -3, -3, -3, -3, -3, -3, -3, 
           -3,  0,  0,  0,  0,  0,  0, -3, 
           -3,  0,  2,  4,  4,  2,  0, -3, 
           -3,  0,  4,  5,  5,  4,  0, -3, 
           -3,  0,  4,  5,  5,  4,  0, -3, 
           -3,  1,  2,  4,  4,  2,  1, -3, 
           -3,  2,  1,  1,  1,  1,  2, -3, 
           -3, -3,-10, -3, -3,-10, -3, -3 ],
      # Rook
      R: [   4,  4,  4,  4,  4,  4,  4,  4,
            16, 16, 16, 16, 16, 16, 16, 16,
            -4,  0,  0,  0,  0,  0,  0, -4,
            -4,  0,  0,  0,  0,  0,  0, -4,
            -4,  0,  0,  0,  0,  0,  0, -4,
            -4,  0,  0,  0,  0,  0,  0, -4,
            -4,  0,  0,  0,  0,  0,  0, -4,
             0,  0,  0,  2,  2,  0,  0,  0 ],
      # Queen
      Q: [  0,  0,  0,  1,  1,  0,  0,  0, 
            0,  0,  1,  2,  2,  1,  0,  0, 
            0,  1,  2,  2,  2,  2,  1,  0, 
            0,  1,  2,  3,  3,  2,  1,  0, 
            0,  1,  2,  3,  3,  2,  1,  0, 
            0,  1,  1,  2,  2,  1,  1,  0, 
            0,  0,  1,  1,  1,  1,  0,  0, 
           -6, -6, -6, -6, -6, -6, -6, -6 ] }

    KING_BASE = {
      false => [ -52, -50, -50, -50, -50, -50, -50, -52,   # In early game, encourage the king to stay on back 
                 -50, -48, -48, -48, -48, -48, -48, -50,   # row defended by friendly pieces.
                 -48, -46, -46, -46, -46, -46, -46, -48,
                 -46, -44, -44, -44, -44, -44, -44, -46,
                 -44, -42, -42, -42, -42, -42, -42, -44,
                 -42, -40, -40, -40, -40, -40, -40, -42,
                 -16, -15, -20, -20, -20, -20, -15, -16,
                   0,  20,  30, -30,   0, -20,  30,  20 ],

       true => [-30,-20,-10,  0,  0,-10,-20,-30,     # In end game (when few friendly pieces are available
                -20,-10,  0, 10, 10,  0,-10,-20,     # to protect king), the king should move toward the center
                -10,  0, 10, 20, 20, 10,  0,-10,     # and avoid getting trapped in corners.
                  0, 10, 20, 30, 30, 20, 10,  0,
                  0, 10, 20, 30, 30, 20, 10,  0,
                -10,  0, 10, 20, 20, 10,  0,-10,
                -20,-10,  0, 10, 10,  0,-10,-20,
                -30,-20,-10,  0,  0,-10,-20,-30 ] }

    
    MIRROR = [ 56, 57, 58, 59, 60, 61, 62, 63,  # Used to create a mirror image of the base PST
               48, 49, 50, 51, 52, 53, 54, 55,  # during initialization.
               40, 41, 42, 43, 44, 45, 46, 47,
               32, 33, 34, 35, 36, 37, 38, 39,
               24, 25, 26, 27, 28, 29, 30, 31,
               16, 17, 18, 19, 20, 21, 22, 23,
                8,  9, 10, 11, 12, 13, 14, 15,
                0,  1,  2,  3,  4,  5,  6,  7 ]


    # Initialize Piece Square Tables for each color, endgame status, and piece type.
    def self.create_pst
      pst = { w: { false => {}, true => {} }, 
              b: { false => {}, true => {} } }
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
      64.times.map { |i| arr[MIRROR[i]] }
    end

    PST = create_pst

    EVAL_GRAIN = 1

    # The main evaluation method.  Calls methods for calculation of each evaluation component,
    # then divides the total eval score by EVAL_GRAIN to achieve the desired 'coarseness' of evaluation.
    def self.evaluate(position)
      $evaluation_calls += 1 
      # ((net_material(position) + mobility(position) + net_king_tropism(position))/EVAL_GRAIN).round.to_i
      net_material(position) + net_king_tropism(position) + mobility(position) 
    end

    # Sums up the value of all pieces in play for the given side (without any positional bonuses/penalties).
    def self.base_material(position, side)
      position.pieces[side].inject(0) { |total, (key, piece)| total += piece.class.value }
    end

    private

    # Returns the net value of all pieces in play (adjusted by their location on board)
    # relative to the current side to move. Material subtotals for each side are incrementally updated 
    # during make/unmake.
    def self.net_material(position)
      (position.own_material - position.enemy_material)
    end

    # Return the net king tropism bonus.  Each side is awarded a bonus based on the proximity of its pieces
    # to the enemy king.  King tropism bonuses for each side are incrementally updated during make and unmake.
    def self.net_king_tropism(pos)
      pos.own_tropism - pos.enemy_tropism
    end

    # Award a bonus/penalty depending on which side (if any) is in check.
    def self.mobility(position)  
      if position.in_check?
        -350
      elsif position.enemy_in_check?
        350
      else
        0
      end
    end

    # Award a bonus/penalty for each piece in play based on the value of the piece and its distance 
    # to the opposing king.
    def self.king_tropism(pos, side, enemy_king_location=nil)
      sum = 0 
      enemy_king_location ||= pos.enemy_king_location
      pos.pieces[side].each do |loc, piece|
        sum += Tropism::get_bonus(piece, loc, enemy_king_location)
      end
      return sum
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
      PST[piece.color][endgame][piece.class.type][loc.index]
    end

  end
end 











