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
  module Position

    class ChessPosition # Mutable description of the game state as of a specific turn.
      attr_accessor :board, :pieces, :side_to_move, :enemy, :halfmove_clock, :castle, :enp_target, 
                    :hash, :king_location

      def initialize(board, pieces, side_to_move, halfmove_clock)
        @board, @pieces, @side_to_move, @halfmove_clock = board, pieces, side_to_move, halfmove_clock
        @enemy = FLIP_COLOR[@side_to_move]
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

      def to_s  # return a string decribing the position in Forsyth-Edwards Notation.
        GUI::position_to_fen(self)
      end

      def inspect
        "<Chess::Position::ChessPosition <@board:#{@board.inspect}> 
         <@pieces:#{@pieces.inspect}>, <@side_to_move:#{@side_to_move}>>"
      end

      # These methods will be re-written to make use of Move::MoveList class:

      def get_moves # returns a sorted array of all possible moves for the current player.
        promotion_captures, captures, promotions, moves = [], [], [], []

        active_pieces.each do |key, piece| 
          piece.get_moves(self, key, moves, captures, promotions, promotion_captures)
        end
        sort_captures!(captures) # sort captures by MVV-LVA heuristic
        sort_moves!(moves)  # sort regular moves by History or Killer heuristic

        # ideally, killer moves should be searched before captures...
        # append move lists together in reasonable order:
        promotion_captures + captures + promotions + MoveGen::get_castles(self) + moves 
      end
      alias :edges :get_moves

      def get_captures # returns a sorted array of all possible moves for the current player.
        captures, promotion_captures = [], []
        active_pieces.each do |key, piece| 
          piece.get_captures(self, key, captures, promotion_captures)
        end
        sort_captures!(captures)
        
        promotion_captures + captures
      end
      alias :tactical_edges :get_captures


      def sort_captures!(captures)
        captures.sort! { |x,y| y.mvv_lva <=> x.mvv_lva } 
      end

      def sort_moves!(moves) # sort remaining (non-capture)
        # moves.sort! {  }
      end

    end

  end
end











