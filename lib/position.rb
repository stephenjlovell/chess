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
  module Position

    class ChessPosition # Mutable description of the game state as of a specific turn.
      attr_accessor :board, :pieces, :side_to_move, :enemy, :halfmove_clock, :castle, :enp_target, 
                    :hash, :king_location

      def initialize(board, pieces, side_to_move, halfmove_clock)
        @board, @pieces, @side_to_move, @halfmove_clock = board, pieces, side_to_move, halfmove_clock
        @enemy = @side_to_move == :w ? :b : :w
        @enp_target, @castle = nil, 0b1111
        @hash = @board.hash
        @king_location = { w: Location::get_location(2,6), b: Location::get_location(9,6) }
      end

      def active_pieces
        @pieces[@side_to_move]
      end

      def enemy_pieces
        @pieces[@enemy]
      end

      def active_king_location
        @king_location[@side_to_move]
      end

      def active_king_location=(location)
        @king_location[@side_to_move] = location
      end

      def enemy_king_location
        @king_location[@enemy]
      end

      def value
        Evaluation::evaluate(self)
      end

      def in_check?
        @board.king_in_check?(self, @side_to_move)
      end

      def enemy_in_check?
        @board.king_in_check?(self, @enemy)
      end

      def avoids_check?(from, to)
        @board.avoids_check?(self, from, to, @side_to_move)
      end

      def to_s
        # return a string decribing the position in Forsyth-Edwards Notation.
      end

      def inspect
        "<Application::Position::ChessPosition <@board:#{@board.inspect}> 
         <@pieces:#{@pieces.inspect}>, <@side_to_move:#{@side_to_move}>>"
      end

      # These methods will be re-written to make use of Movement::MoveList class:

      def get_moves # returns a sorted array of all possible moves for the current player.
        moves = []
        active_pieces.each { |key, piece| moves += piece.get_moves(key, self) }
        moves += MoveGen::get_castles(self)
        sort_moves!(moves)
        return moves      
      end
      alias :edges :get_moves

      def get_captures # returns a sorted array of all possible moves for the current player.
        moves = []
        active_pieces.each { |key, piece| moves += piece.get_captures(key, self) }
        sort_moves!(moves)
        return moves      
      end
      alias :tactical_edges :get_captures

      def get_enemy_captures
        moves = []
        enemy_pieces.each { |key, piece| moves += piece.get_captures(key, self) }
        sort_moves!(moves)
        return moves      
      end

      def sort_moves!(moves)
        moves.sort! { |x,y| y.mvv_lva <=> x.mvv_lva }  # also sort non-captures by Killer Heuristic?
      end

    end

  end
end











