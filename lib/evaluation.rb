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
    # the following factors:
    # 
    # 1. Material Balance - This simply sums the value of each piece in play.
    # 2. King Tropism - A bonus is given for each piece based on its closeness to the enemy king.
    # 3. Piece-Square Tables - Small bunuses/penalties are applied based on piece type/location.
    # 4. Piece Mobility - Each piece is awarded a bonus based on how many squares it can move to. 
    # 5. Pawn Structure - Adjusts pawn values are by looking for several pawn structure patterns.

    EVAL_GRAIN = 1

    # The main evaluation method.  Calls methods for calculation of each evaluation component,
    # then divides the total eval score by EVAL_GRAIN to achieve the desired 'coarseness' of evaluation.
    def self.evaluate(pos, in_check)
      $evaluation_calls += 1
      net_placement(pos.pieces, pos.side_to_move)
    end

    # Sums up the value of all pieces in play for the given side (without any positional bonuses/penalties).
    def self.base_material(pos, side)
      pos.pieces.get_base_material(side) - Pieces::PIECE_VALUES[:K]    
    end
  end
end 











