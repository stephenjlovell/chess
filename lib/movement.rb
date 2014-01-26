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

    module Reversible # Moves other than pawn moves and captures
      def make_clock_adjustment(position)
        position.halfmove_clock += 1
      end

      def unmake_clock_adjustment(position)
        position.halfmove_clock -= 1
      end

      def reversible?
        true
      end
    end

    module Irreversible # Pawn moves and captures
      def make_clock_adjustment(position) # reset halfmove clock to zero. 
        @halfmove_clock = position.halfmove_clock
        position.halfmove_clock = 0
      end

      def unmake_clock_adjustment(position)
        position.halfmove_clock = @halfmove_clock # Store halfmove clock for unmake.
      end

      def reversible?
        false
      end
    end

    module MakesCapture # Mixes in methods shared among capture strategies 
      include Irreversible
      attr_accessor :captured_piece
      
      def initialize(captured_piece)
        @captured_piece = captured_piece
      end

      def make!(position, piece, from, to)
        relocate_piece(position, piece, from, to)
        make_clock_adjustment(position)
        position.enemy_pieces.delete(to)
      end

      def unmake!(position, piece, from, to)
        relocate_piece(position, piece, to, from)
        unmake_clock_adjustment(position)
        position.board[to] = @captured_piece.symbol
        position.enemy_pieces[to] = @captured_piece
      end

      def capture?
        true
      end

      def hash(piece, from, to)
        puts self.class if @captured_piece.nil?
        from_to_key(piece, from, to) ^ Memory::psq_key(@captured_piece, to)
      end

      def mvv_lva(moved_piece)  # Most valuable victim, least valuable attacker heuristic.
        @captured_piece.class.value - moved_piece.class.id  # Used for move ordering captures.
      end
    end

    class MoveStrategy  # Generic template and shared behavior for move strategies.
      # concrete strategy classes must include either Reversible or Irreversible module.
      def make!(position, piece, from, to)
        relocate_piece(position, piece, from, to)
        make_clock_adjustment(position)
      end

      def unmake!(position, piece, from, to)
        relocate_piece(position, piece, to, from)
        unmake_clock_adjustment(position)
      end

      def capture?
        false
      end

      def hash(piece, from, to)
        from_to_key(piece, from, to)
      end

      def relocate_piece(position, piece, from, to)
        position.active_pieces.delete(from) # relocate piece within piece list
        position.active_pieces[to] = piece
        position.board[from] = nil  # relocate piece on board.
        position.board[to] = piece.symbol
      end

      def from_to_key(piece, from, to)
        Memory::psq_key(piece, from) ^ Memory::psq_key(piece, to)
      end
    end

    class RegularMove < MoveStrategy
      include Reversible
    end

    class KingMove < MoveStrategy
      include Reversible

      def make!(position, piece, from, to)
        relocate_piece(position, piece, from, to)
        position.active_king_location = to
        make_clock_adjustment(position)
      end

      def unmake!(position, piece, from, to)
        relocate_piece(position, piece, to, from)
        position.active_king_location = from
        unmake_clock_adjustment(position)
      end
    end

    class RegularCapture < MoveStrategy #  Stores captured piece for unmake purposes.
      include MakesCapture
    end

    class KingCapture < MoveStrategy
      include MakesCapture

      def make!(position, piece, from, to)
        relocate_piece(position, piece, from, to)
        position.active_king_location = to
        make_clock_adjustment(position)
        position.enemy_pieces.delete(to)
      end

      def unmake!(position, piece, from, to)
        relocate_piece(position, piece, to, from)
        position.active_king_location = from
        unmake_clock_adjustment(position)
        position.board[to] = @captured_piece.symbol
        position.enemy_pieces[to] = @captured_piece
      end
    end

    class EnPassantCapture < MoveStrategy
      include MakesCapture

      def initialize(captured_piece, enp_target)
        @captured_piece, @enp_target = captured_piece, enp_target
      end

      def make!(position, piece, from, to)
        relocate_piece(position, piece, from, to)
        make_clock_adjustment(position)
        position.board[@enp_target] = nil
        position.enemy_pieces.delete(@enp_target)
      end

      def unmake!(position, piece, from, to)
        relocate_piece(position, piece, to, from)
        unmake_clock_adjustment(position)
        position.board[@enp_target] = @captured_piece.symbol
        position.enemy_pieces[@enp_target] = @captured_piece
      end

      def hash(piece, from, to)
        from_to_key(piece, from, to) ^ Memory::psq_key(@captured_piece, @enp_target)
      end
    end

    class PawnMove < MoveStrategy
      include Irreversible
    end

    class EnPassantAdvance < MoveStrategy # Sets or removes the enp_target from position object.
      include Irreversible
      def make!(position, piece, from, to)
        relocate_piece(position, piece, from, to)
        make_clock_adjustment(position)
        position.enp_target = to # Set enp_target to new target square
      end

      def unmake!(position, piece, from, to)
        relocate_piece(position, piece, to, from)
        unmake_clock_adjustment(position)
        position.enp_target = nil
      end

      def hash(piece, from, to)
        from_to_key(piece, from, to) ^ Memory::enp_key(to)
      end
    end

    class PawnPromotion < MoveStrategy # Stores the existing pawn in move object and places a new Queen.
      include Irreversible
      def initialize(position)
        @queen = Pieces::Queen.new(@position.side_to_move)
      end

      def make!(position, piece, from, to)
        relocate_piece(position, @queen, from, to)
        make_clock_adjustment(position)
      end

      def unmake!(position, piece, from, to)
        relocate_piece(position, piece, to, from)
        unmake_clock_adjustment(position)
      end

      def hash(piece, from, to)
        Memory::psq_key(piece, from) ^ Memory::psq_key(@queen, to)
      end
    end

    class Castle < MoveStrategy  # Stores movement info for the rook to be moved.
      # King movement information will be stored in the Move class properties.
      include Reversible

      def initialize(rook, castle_from, castle_to)
        @rook, @castle_from, @castle_to = rook, castle_from, castle_to
      end

      def make!(position, piece, from, to)
        relocate_piece(position, piece, from, to)
        relocate_piece(position, @rook, @castle_from, @castle_to)
        position.active_king_location = to
      end

      def unmake!(position, piece, from, to)
        relocate_piece(position, piece, to, from)
        relocate_piece(position, @rook, @castle_to, @castle_from)
        position.active_king_location = from
      end

      def hash(piece, from, to)
        from_to_key(piece, from, to) ^ from_to_key(@castle_from, @castle_to, @rook)
      end
    end

    class Move
      attr_reader :moved_piece, :from, :to, :enp_target

      def initialize(moved_piece, from, to, strategy)
        @moved_piece, @from, @to, @strategy = moved_piece, from, to, strategy
      end

      def make!(position)
        @enp_target = position.enp_target  # save old enp_target for make/unmake
        position.enp_target = nil
        @strategy.make!(position, @moved_piece, @from, @to)  # delegate to the strategy class.
      end

      def unmake!(position)
        @strategy.unmake!(position, @moved_piece, @from, @to)
        position.enp_target = @enp_target
      end

      def capture?
        @strategy.respond_to?(:mvv_lva)
      end

      def mvv_lva
        capture? ? @strategy.mvv_lva(@moved_piece) : 0
      end

      def strategy
        @strategy.class
      end

      def hash # Uses Zobrist hashing to represent the move as a 64-bit unsigned long int.
        @hash ||= @strategy.hash(@moved_piece, @from, @to) ^ Memory::enp_key(@enp_target)
      end

      def to_s
        s = @strategy
        if s.capture?
          "#{@moved_piece} x #{s.captured_piece} #{@from} to #{@to}"
        elsif strategy == Castle
          "Castle {@moved_piece} #{@from} to #{@to}, #{s.rook} #{s.castle_from} to #{s.castle_to}"
        elsif strategy == PawnPromotion
          "#{s.queen} Promotion #{@moved_piece} #{@from} to #{@to}"
        else
          "#{@moved_piece} #{@from} to #{@to}"
        end
      end
    end

  end
end






