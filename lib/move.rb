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
  module Move

    module Reversible # moves other than pawn moves and captures
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

    module Irreversible # pawn moves and captures
      def make_clock_adjustment(position) # reset halfmove clock to zero. 
        @halfmove_clock = position.halfmove_clock # store halfmove clock for unmake.
        position.halfmove_clock = 0
      end

      def unmake_clock_adjustment(position)
        position.halfmove_clock = @halfmove_clock 
      end

      def reversible?
        false
      end
    end

    module MakesCapture # mixes in methods shared among capture strategies 
      include Irreversible
      attr_accessor :captured_piece
      
      def initialize(captured_piece)
        @captured_piece, @own_material, @enemy_material = captured_piece, 0, 0
      end

      def make!(position, piece, from, to)
        make_relocate_piece(position, piece, from, to)
        make_clock_adjustment(position)
        position.enemy_pieces.delete(to)
        @enemy_material -= Evaluation::adjusted_value(position, @captured_piece, to)
      end

      def unmake!(position, piece, from, to)
        relocate_piece(position, piece, to, from)
        unmake_clock_adjustment(position)
        position.board[to] = @captured_piece.symbol
        position.enemy_pieces[to] = @captured_piece
      end

      def print(piece, from, to)
        "#{piece} x #{@captured_piece} #{from} to #{to}"
      end

      def inspect
        "<#{self.class} <@captured_piece:#{@captured_piece}> <@own_material:#{@own_material}>" +
        "<@enemy_material:#{@enemy_material}>>"
      end


      def hash(piece, from, to)
        from_to_key(piece, from, to) ^ Memory::psq_key(@captured_piece, to)
      end


      def mvv_lva(piece)  # Most valuable victim, least valuable attacker heuristic.
        @mvv_lva ||= @captured_piece.class.value - piece.class.id  # Used for move ordering captures.
      end


    end

    class MoveStrategy  # Generic template and shared behavior for move strategies.
      # Concrete strategy classes must include either Reversible or Irreversible module.
      attr_reader :own_material, :enemy_material

      def initialize
        @own_material, @enemy_material = 0, 0
      end

      def make!(position, piece, from, to)
        make_relocate_piece(position, piece, from, to)
        make_clock_adjustment(position)
      end

      def unmake!(position, piece, from, to)
        relocate_piece(position, piece, to, from)
        unmake_clock_adjustment(position)
      end

      def print(piece, from, to)
        "#{piece} #{from} to #{to}"
      end

      def inspect
        "<#{self.class} <@own_material:#{@own_material}> <@enemy_material:#{@enemy_material}>>"
      end

      def hash(piece, from, to)
        from_to_key(piece, from, to)
      end

      def make_relocate_piece(position, piece, from, to)
        relocate_piece(position, piece, from, to)
        @own_material += (Evaluation::pst_value(position, piece, to) 
                          - Evaluation::pst_value(position, piece, from))
      end

      def relocate_piece(position, piece, from, to)
        position.own_pieces.delete(from) # relocate piece within piece list
        position.own_pieces[to] = piece
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
        make_relocate_piece(position, piece, from, to)
        position.own_king_location = to  # update king location
        make_clock_adjustment(position)
      end

      def unmake!(position, piece, from, to)
        relocate_piece(position, piece, to, from)
        position.own_king_location = from  # update king location
        unmake_clock_adjustment(position)
      end
    end

    class RegularCapture < MoveStrategy #  Stores captured piece for unmake purposes.
      include MakesCapture
    end

    class KingCapture < MoveStrategy
      include MakesCapture

      def make!(position, piece, from, to)
        make_relocate_piece(position, piece, from, to)
        position.own_king_location = to  # update king location
        make_clock_adjustment(position)
        position.enemy_pieces.delete(to)
        @enemy_material -= Evaluation::adjusted_value(position, @captured_piece, to)
      end

      def unmake!(position, piece, from, to)
        relocate_piece(position, piece, to, from)
        position.own_king_location = from  # update king location
        unmake_clock_adjustment(position)
        position.board[to] = @captured_piece.symbol
        position.enemy_pieces[to] = @captured_piece
      end
    end

    class EnPassantCapture < MoveStrategy
      include MakesCapture

      def initialize(captured_piece, enp_target)
        @captured_piece, @enp_target = captured_piece, enp_target
        @own_material, @enemy_material = 0, 0
      end

      def make!(position, piece, from, to)
        make_relocate_piece(position, piece, from, to)
        make_clock_adjustment(position)
        position.board[@enp_target] = nil
        position.enemy_pieces.delete(@enp_target)
        @enemy_material -= Evaluation::adjusted_value(position, @captured_piece, @enp_target)
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

      def print(piece, from, to)
        "#{piece} enp x #{@captured_piece} #{from} to #{to}"
      end

    end

    class PawnMove < MoveStrategy
      include Irreversible
    end

    class EnPassantAdvance < MoveStrategy # Sets or removes the enp_target from position object.
      include Irreversible
      def make!(position, piece, from, to)
        make_relocate_piece(position, piece, from, to)
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
      def initialize(side_to_move)
        @queen = Pieces::Queen.new(side_to_move)
        @own_material, @enemy_material = 0, 0
      end

      def make!(position, piece, from, to)
        relocate_piece(position, @queen, from, to) # do not add PST delta for this move, since the moved piece
        make_clock_adjustment(position)            # is replaced by a new queen.
        @own_material += (Evaluation::adjusted_value(position, @queen, to) 
                          - Evaluation::adjusted_value(position, piece, from))
      end

      def unmake!(position, piece, from, to)
        relocate_piece(position, piece, to, from)
        unmake_clock_adjustment(position)
      end

      def print(piece, from, to)
        "#{piece} promotion #{from} to #{to}"
      end

      def hash(piece, from, to)
        Memory::psq_key(piece, from) ^ Memory::psq_key(@queen, to)
      end
    end

    class PawnPromotionCapture < MoveStrategy
      include MakesCapture

      def initialize(captured_piece)  
        @queen, @captured_piece = Pieces::Queen.new(FLIP_COLOR[captured_piece.color]), captured_piece
        @own_material, @enemy_material = 0, 0
      end

      def make!(position, piece, from, to)
        relocate_piece(position, @queen, from, to) # do not add PST delta for this move, since the moved piece
        make_clock_adjustment(position)            # is replaced by a new queen.
        position.enemy_pieces.delete(to)
        @own_material += (Evaluation::adjusted_value(position, @queen, to) 
                          - Evaluation::adjusted_value(position, piece, from))
        @enemy_material -= Evaluation::adjusted_value(position, @captured_piece, to)
      end

      def unmake!(position, piece, from, to)
        relocate_piece(position, piece, to, from)
        unmake_clock_adjustment(position)
        position.board[to] = @captured_piece.symbol
        position.enemy_pieces[to] = @captured_piece
      end

      def print(piece, from, to)
        "#{piece} x #{@captured_piece} promotion #{from} to #{to}"
      end

      def hash(piece, from, to)
        Memory::psq_key(piece, from) ^ Memory::psq_key(@captured_piece, to) ^ Memory::psq_key(@queen, to)
      end

    end

    class Castle < MoveStrategy  # Stores Move info for the rook to be moved.
      # King Move information will be stored in the Move class properties.
      include Reversible

      attr_accessor :rook, :rook_from, :rook_to
      def initialize(rook, rook_from, rook_to)
        @rook, @rook_from, @rook_to = rook, rook_from, rook_to
        @own_material, @enemy_material = 0, 0
      end

      def make!(position, piece, from, to)
        make_relocate_piece(position, piece, from, to)
        make_relocate_piece(position, @rook, @rook_from, @rook_to)
        make_clock_adjustment(position)
        position.own_king_location = to
      end

      def unmake!(position, piece, from, to)
        relocate_piece(position, piece, to, from)
        relocate_piece(position, @rook, @rook_to, @rook_from)
        unmake_clock_adjustment(position)
        position.own_king_location = from
      end

      def print(piece, from, to)
        "#{piece} castle #{from} to #{to}"
      end

      def hash(piece, from, to)
        from_to_key(piece, from, to) ^ from_to_key(@rook, @rook_from, @rook_to)
      end
    end


    class Move
      attr_reader :piece, :from, :to, :enp_target, :see

      def initialize(piece, from, to, strategy)
        @piece, @from, @to, @strategy = piece, from, to, strategy
      end

      def make!(position)
        begin
        @enp_target, @castle_rights = position.enp_target, position.castle   # save old values for make/unmake
        position.enp_target = nil
        @strategy.make!(position, @piece, @from, @to)  # delegate to the strategy class.
        position.own_material += @strategy.own_material
        position.enemy_material += @strategy.enemy_material
        rescue => err
          puts "TT Size: #{$tt.size}"
          puts self.inspect
          raise err
        end 
      end

      def unmake!(position)
        position.own_material -= @strategy.own_material
        position.enemy_material -= @strategy.enemy_material
        @strategy.unmake!(position, @piece, @from, @to)  # delegate to the strategy class.
        position.enp_target, position.castle = @enp_target, @castle_rights
      end

      def mvv_lva
        begin
          @strategy.mvv_lva(@piece)
        rescue => err
          puts "TT Size: #{$tt.size}"
          puts self.inspect
          raise err
        end

      end

      def see_score(position)
        @see ||= Search::get_see_score(position, @to)
      end

      def strategy
        @strategy.class
      end

      def hash # Uses Zobrist hashing to represent the move as a 64-bit unsigned long int.
        @hash ||= @strategy.hash(@piece, @from, @to) ^ Memory::enp_key(@enp_target)
      end

      def print
        @strategy.print(@piece, @from, @to)
      end

      def to_s
        @from.to_s + @to.to_s
      end

      def inspect
        "<Chess::Move::Move <@piece:#{@piece}> <@from:#{@from}> <@to:#{@to}>" + 
        "<@enp_target:#{@enp_target}> <@see:#{@see}> <@strategy:#{@strategy.inspect}>>"
      end

    end

    class Factory  # A simplified interface for instantiating Move objects.
      PROCS = { regular_move: Proc.new { |*args| RegularMove.new },
                king_move: Proc.new { |*args| KingMove.new },
                regular_capture: Proc.new { |*args| RegularCapture.new(*args) },
                king_capture: Proc.new { |*args| KingCapture.new(*args) },
                enp_capture: Proc.new { |*args| EnPassantCapture.new(*args) },
                pawn_move: Proc.new { |*args| PawnMove.new },
                enp_advance: Proc.new { |*args| EnPassantAdvance.new },
                pawn_promotion: Proc.new { |*args| PawnPromotion.new(*args) },
                pawn_promotion_capture: Proc.new { |*args| PawnPromotionCapture.new(*args) },
                castle: Proc.new { |*args| Castle.new(*args) } } 

      def self.build(piece, from, to, sym, *args)  # create a Move object containing the specified strategy.
        raise "no product strategy #{sym} available for Move::MoveFactory" unless PROCS[sym]
        Move.new(piece, from, to, PROCS[sym].call(*args)) 
      end
    end

  end
end






