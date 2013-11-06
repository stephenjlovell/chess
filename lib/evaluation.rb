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

    def self.evaluate(position) # return heuristic value of specified position.
      friend = position.side_to_move
      enemy = friend == :w ? :b : :w
      return net_raw_material(position,friend, enemy)
    end

    def self.net_raw_material(position, friend, enemy) # net material value for side to move.
      raw_material(position, friend) - raw_material(position, enemy)
    end

    def self.raw_material(position, side) # =~ 1,040 at start
      position.pieces[side].inject(0.0) { |total, (key, piece)| total += piece.value }  
    end


    # reversible Piece-Square Tables
    PST = { 

      wP:[]
      bP:[]

      wR:[]
      bR:[]

      wN:[]
      bN:[]

      wB:[]
      wB:[]

      wQ:[]
      bQ:[]

      wK:[]
      bK:[]

    }




  end
end 











