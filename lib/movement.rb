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

    module MakesCapture # Mixes in methods shared among capture strategies 
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
        hash_piece(piece, from, to) ^ Memory::get_key(@captured_piece, to)
      end

      def mvv_lva_value(moved_piece)
        @captured_piece.class.value / @moved_piece.class.value
      end
    end

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
        hash_piece(piece, from, to)
      end

      def relocate_piece(position, piece, from, to)
        position.active_pieces.delete(from) # relocate piece within piece list
        position.active_pieces[to] = piece
        position.board[from] = nil  # relocate piece on board.
        position.board[to] = piece.symbol
      end

      def hash_piece(piece, from, to)
        Memory::get_key(piece, from) ^ Memory::get_key(piece, to)
      end
    end

    class RegularMove < MoveStrategy
      include Reversible
    end

    class RegularCapture < MoveStrategy #  Stores captured piece for unmake purposes.
      include Irreversible
      include MakesCapture
    end

    # class PawnCapture < MoveStrategy
    #   include Irreversible
    #   include MakesCapture
    # end

    class EnPassantCapture < MoveStrategy
      include Irreversible
      include MakesCapture

      def initialize(captured_piece, en_passant_target)
        @captured_piece, @en_passant_target = captured_piece, en_passant_target
      end

      def make!(position, piece, from, to)
        relocate_piece(position, piece, from, to)
        make_clock_adjustment(position)
        position.board[@en_passant_target] = nil
        position.enemy_pieces.delete(@en_passant_target)
      end

      def unmake!(position, piece, from, to)
        relocate_piece(position, piece, to, from)
        unmake_clock_adjustment(position)
        position.board[@en_passant_target] = @captured_piece.symbol
        position.enemy_pieces[@en_passant_target] = @captured_piece
      end

      def hash(piece, from, to)
        hash_piece(piece, from, to) ^ Memory::get_key(@captured_piece, @en_passant_target)
      end
    end

    class PawnMove < MoveStrategy
      include Irreversible
    end

    class EnPassantAdvance < MoveStrategy # Sets or removes the en_passant_target from position object.
      include Irreversible
      def make!(position, piece, from, to)
        relocate_piece(position, piece, from, to)
        make_clock_adjustment(position)
        position.options[:en_passant_target] = to
      end

      def unmake!(position, piece, from, to)
        relocate_piece(position, piece, to, from)
        unmake_clock_adjustment(position)
        position.options[:en_passant_target] = nil
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
        Memory::get_key(piece, from) ^ Memory::get_key(@queen, to)
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
        # remove castling option for the appropriate side
      end

      def unmake!(position, piece, from, to)
        relocate_piece(position, piece, to, from)
        relocate_piece(position, @rook, @castle_to, @castle_from)
        # add back castling option for the appropriate side
      end

      def hash(piece, from, to)
        hash_piece(piece, from, to) ^ hash_piece(@castle_from, @castle_to, @rook)
      end
    end


    class Move
      attr_reader :moved_piece, :from, :to

      def initialize(moved_piece, from, to, strategy)
        @moved_piece, @from, @to, @strategy = moved_piece, from, to, strategy
      end

      def make!(position)
        @strategy.make!(position, @moved_piece, @from, @to)  # delegate to the strategy class.
      end

      def unmake!(position)
        @strategy.unmake!(position, @moved_piece, @from, @to)
      end

      def capture_value
        0 # need to be able to selectively extend moves with high mvv_lva during search.
      end

      def strategy
        @strategy.class
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

      def hash # Uses Zobrist hashing to represent the move as a 64-bit unsigned long int.
        @hash ||= @strategy.hash(@moved_piece, @from, @to)
      end
    end

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
      pos.hash ^= move.hash 
    end

  end
end






