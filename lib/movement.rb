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

#  Move strategies required:
#
#    Castling - will require some additional information to be stored in Move object.
#      - when creating a castle move, could attach the additional info within singleton methods? 
#
#    
#
#    Pawn EnPassant Capture (EnPassant Attack) get target square from position.en_passant_target

    module MakesCapture
      # any behavior shared between capture strategies (RegularCapture and EnPassantCapture)
      # is defined in Mixin methods here.

      def initialize(captured_piece)
        @captured_piece = captured_piece
      end

      def mvv_lva_value(moved_piece)
        @captured_piece.class.value / @moved_piece.class.value
      end

    end


    class MoveStrategy  # Generic template for move strategies.  
      # Any shared strategy behavior can also be defined here.
      def initialize
      end

      def make!(position)
      end

      def unmake!(position)
      end
    end

    class RegularMove < MoveStrategy

    end

    class RegularCapture < MoveStrategy #  Stores captured piece for unmake purposes.
      include MakesCapture

    end

    class EnPassantCapture < MoveStrategy
      include MakesCapture

      def make!(position) 
        # Get target square from position.en_passant_target
      end

      def unmake!(position)
      end

    end

    class EnPassantAdvance < MoveStrategy
      # Pawn double advance (EnPassant Target) 
      # Set or remove the en_passant_target from position object
    end

    class PawnPromotion < MoveStrategy
      #  stores the existing pawn in move object (for unmaking) and places a new Queen.
    end

    class Castle < MoveStrategy
      # Stores movement info for the rook to be moved.
      # King movement information will be stored in the Move class properties.

      def initialize(castle_from, castle_to, rook)
        @castle_from, @castle_to, @rook = castle_from, castle_to, rook
      end

    end

    class Move
      attr_reader :from, :to, :moved_piece

      def initialize(from, to)
        @from, @to = from, to
      end

      def make!(position)
        @strategy.make!(position)  # delegate to the strategy class.
      end

      def unmake!(position)
        @strategy.unmake!(position)
      end


      def hash
        # Uses Zobrist hashing to represent the move as a 64-bit unsigned long int.
      end

    end


    class MoveList
      # notional place to store, organize, and sort moves

      attr_accessor :captures, :regular_moves, :castles, :checks

      def get_moves(position)

      end

      def next_move
        # return the next move from the move stack
      end
    end



    def self.make!(position, move)
      # Mutates position by making the specified move.
      # Converts the position into a child position.

    end


    def self.unmake!(position, move)
      # mutates position by reversing the specified move.  
      # Converts the position into its parent position.

    end


  end
end






