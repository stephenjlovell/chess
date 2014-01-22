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
  module Movement

    module MakesCapture # Any behavior shared between capture strategies 
      # i.e. (RegularCapture and EnPassantCapture) is defined in Mixin methods here.
      def initialize(captured_piece)
        @captured_piece = captured_piece
      end
      
      def make!(position, piece, from, to)
        relocate_piece!(position, piece, from, to)
        position.enemy_pieces.delete(to)
      end

      def unmake!(position, piece, from, to)
        relocate_piece!(position, piece, to, from)
        position.enemy_pieces[to] = @captured_piece
      end

      def mvv_lva_value(moved_piece)
        @captured_piece.class.value / @moved_piece.class.value
      end

      def hash

      end
    end


    class MoveStrategy  # Generic template for move strategies. Shared strategy behavior is defined here.
      def initialize
      end

      def make!(position, piece, from, to)
      end

      def unmake!(position, piece, from, to)
      end

      def relocate_piece!(position, piece, from, to)
        position.active_pieces.delete(from) # relocate piece within piece list
        position.active_pieces[to] = piece
        position.board[from] = nil  # relocate piece on board.
        position.board[to] = piece.symbol
      end
    end

    class RegularMove < MoveStrategy
      def make!(position, piece, from, to)
        relocate_piece!(position, piece, from, to)
      end

      def unmake!(position, piece, from, to)
        relocate_piece!(position, piece, to, from)
      end
    end

    class RegularCapture < MoveStrategy #  Stores captured piece for unmake purposes.
      include MakesCapture
    end

    class EnPassantCapture < MoveStrategy
      include MakesCapture

      def initialize(captured_piece, en_passant_target)
        @captured_piece, @en_passant_target = captured_piece, en_passant_target
      end

      def make!(position, piece, from, to) # Get target square from position.en_passant_target
        relocate_piece!(position, piece, from, to)
        position.board[@en_passant_target] = nil
        position.enemy_pieces.delete(@en_passant_target)
      end

      def unmake!(position, piece, from, to)
        relocate_piece!(position, piece, to, from)
        position.board[@en_passant_target] = @captured_piece.symbol
        position.enemy_pieces[@en_passant_target] = @captured_piece
      end

      def hash

      end

    end

    class EnPassantAdvance < MoveStrategy # Sets or removes the en_passant_target from position object.
      def make!(position, piece, from, to)
        relocate_piece!(position, piece, from, to)
        position.en_passant_target = to
      end

      def unmake!(position, piece, from, to)
        relocate_piece!(position, piece, to, from)
        position.en_passant_target = nil
      end
    end

    class PawnPromotion < MoveStrategy # Stores the existing pawn in move object and places a new Queen.
      def make!(position, piece, from, to)
        relocate_piece!(position, Pieces::Queen.new(@position.side_to_move) , from, to)
      end

      def unmake!(position, piece, from, to)
        relocate_piece!(position, piece, to, from)
      end
    end

    class Castle < MoveStrategy  # Stores movement info for the rook to be moved.
      # King movement information will be stored in the Move class properties.
      def initialize(castle_from, castle_to, rook)
        @castle_from, @castle_to, @rook = castle_from, castle_to, rook
      end

      def make!(position, piece, from, to)
        relocate_piece!(position, piece, from, to)
        relocate_piece!(position, rook, @castle_from, @castle_to)

        # remove castling option for the appropriate side
      end

      def unmake!(position, piece, from, to)
        relocate_piece!(position, piece, to, from)
        relocate_piece!(position, rook, @castle_to, @castle_from)

        # add back castling option for the appropriate side
      end

      def hash

      end

    end

    class Move
      attr_reader :from, :to, :moved_piece

      def initialize(from, to)
        @from, @to = from, to
      end

      def make!(position)
        @strategy.make!(position, @moved_piece, @from, @to)  # delegate to the strategy class.
      end

      def unmake!(position)
        @strategy.unmake!(position, @moved_piece, @from, @to)
      end

      def strategy
        @strategy.class
      end

      def hash
        # Uses Zobrist hashing to represent the move as a 64-bit unsigned long int.
        @strategy.hash
      end

    end


    class MoveList
      # notional place to store, organize, and sort moves.

      attr_accessor :captures, :regular_moves, :castles, :checks

      def get_moves(position)

      end

      def next_move  # return the next move from the move stack
      end
    end


    def self.make!(position, move) # Mutates position by making the specified move. 
      # Converts the position into a child position.
      move.make!(position)
      switch(position, move)
    end

    def self.unmake!(position, move) # Mutates position by reversing the specified move.  
      # Converts the position into its parent position.
      move.unmake!(position)
      switch(position, move)
    end

    def self.switch(position, move)
      position.side_to_move = position.side_to_move == :w ? :b : :w
      position.hash = position.hash ^ move.hash 
    end


  end
end






