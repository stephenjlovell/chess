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
  module MoveGen

    class MoveList  # Notional place to store, organize, and sort moves more easily.
      attr_accessor :captures, :regular_moves, :castles, :checks

      def get_moves(position)
      end

      def next_move  # return the next move from the move stack
      end
    end

    # Module interface

    def self.make_unmake!(position, move)
      make!(position, move)
      yield 
      unmake!(position, move)
    end

    def self.make!(position, move) # Mutates position by making the specified move. 
      move.make!(position)         # Converts the position into a child position.
      flip(position, move)
    end

    def self.unmake!(position, move) # Mutates position by reversing the specified move.  
      flip(position, move)           # Converts the position into its parent position.
      move.unmake!(position)
    end

    def self.flip(pos, move)
      if pos.side_to_move == :w
        pos.side_to_move, pos.enemy = :b, :w
      else
        pos.side_to_move, pos.enemy = :w, :b
      end
      pos.hash ^= move.hash ^ Memory::side_key
    end

  end
end








