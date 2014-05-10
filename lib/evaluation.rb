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

# require './ext/ruby_chess'

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

    EVAL_GRAIN = 1

    # The main evaluation method.  Calls methods for calculation of each evaluation component,
    # then divides the total eval score by EVAL_GRAIN to achieve the desired 'coarseness' of evaluation.
    def self.evaluate(pos, in_check)
      $evaluation_calls += 1 
      net_placement(pos.pieces, pos.side_to_move) + net_safety(pos, in_check) 
    end

    # Sums up the value of all pieces in play for the given side (without any positional bonuses/penalties).
    def self.base_material(pos, side)
      pos.pieces.get_base_material(side) - Pieces::PIECE_VALUES[:K]    
    end

    private

    # Returns the net value of all pieces in play (adjusted by their location on board)
    # relative to the current side to move. Material subtotals for each side are incrementally updated 
    # during make/unmake.


    # Award a bonus/penalty depending on which side (if any) is in check.
    def self.net_safety(position, in_check)
      in_check ||= position.in_check?  
      if in_check
        -350
      elsif position.enemy_in_check?
        350
      else
        0
      end
    end


    # Return the net king tropism bonus.  Each side is awarded a bonus based on the proximity of its pieces
    # to the enemy king.  King tropism bonuses for each side are incrementally updated during make and unmake.
    def self.net_king_tropism(pos)
      # pos.own_tropism - pos.enemy_tropism
      0
    end

    # Award a bonus/penalty for each piece in play based on the value of the piece and its distance 
    # to the opposing king.
    def self.king_tropism(pos, side, enemy_king_location=nil)
      # sum = 0 
      # enemy_king_location ||= pos.enemy_king_location
      # pos.pieces[side].each do |loc, piece|
      #   sum += Tropism::get_bonus(piece, loc, enemy_king_location)
      # end
      # return sum
      0
    end

    # def self.adjusted_value(position, piece, square, endgame=nil)
    #   Pieces::PIECE_VALUES[piece] + pst_value(position, piece, square, endgame)
    # end    

    # def self.pst_value(position, piece, square, endgame=nil)
    #   endgame = position.endgame?(position.side_to_move) if endgame.nil?
    #   PST[position.side_to_move][endgame][(piece>>1)&7][square]
    # end

  end
end 











