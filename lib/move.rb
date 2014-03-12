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

    #  Move object instances encapsulate all information and logic required to transform a chess position by making
    #  or unmaking a specific move.  Each Move instance contains a strategy object that abstracts out any make/unmake
    #  logic unique to the type of move being made. 
    #  
    #  1. Useage of Move objects follows the Memento pattern.  The position object acts as the 'originator', generating Move
    #     instances for available legal moves.  The MoveGen module acts as 'caretaker', making and rolling back changes
    #     to the originator supplied by the 'memento' (the Move instance).
    #  2. The move object caches incremental changes to the position's material balance, king safety, and hash key, reducing
    #     overhead when the move is unmade during Search.
    #  3. Sequences of Move objects are stored by the MoveHistory class, allowing the human player to undo/redo moves at will.
    
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
          raise Memory::HashCollisionError
        end 
      end

      def unmake!(position)
        position.own_material -= @strategy.own_material
        position.enemy_material -= @strategy.enemy_material
        @strategy.unmake!(position, @piece, @from, @to)  # delegate to the strategy class.
        position.enp_target, position.castle = @enp_target, @castle_rights
      end

      def mvv_lva
        @strategy.mvv_lva(@piece)
      end

      def see_score(position)
        @see ||= Search::get_see_score(position, @to)
      end

      def strategy
        @strategy.class
      end

      def hash # XOR out the old en-passant key, if any.
        @hash ||= @strategy.hash(@piece, @from, @to) ^ Memory::enp_key(@enp_target) ^ Memory::SIDE
      end

      def print
        @strategy.print(@piece, @from, @to)
      end

      def to_s
        @from.to_s + @to.to_s
      end

      def material_swing?
        @strategy.material_swing?
      end

      def inspect
        "<Chess::Move::Move <@piece:#{@piece}> <@from:#{@from}> <@to:#{@to}>" + 
        "<@enp_target:#{@enp_target}> <@see:#{@see}> <@strategy:#{@strategy.inspect}>>"
      end
    end

    # The MoveStrategy class provides a generic template and shared behavior for each move strategy. Concrete strategy 
    # classes include either the Reversible or Irreversible module.  If the concrete strategy class captures an enemy piece, 
    # the strategy class will include the MakesCapture module.

    class MoveStrategy  
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

      # XOR out the key for piece at from, and XOR in the key for piece at to.
      def from_to_key(piece, from, to)
        Memory::psq_key(piece, from) ^ Memory::psq_key(piece, to)
      end

      def material_swing?
        false
      end
    end

    # The Halmove Rule requires that all moves other than pawn moves and captures increment the halfmove clock.
    module Reversible 
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

    # The Halfmove Rule requires that pawn moves and captures reset the halfmove clock to zero.
    module Irreversible 
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

    # All concrete strategy classes involving capture of an enemy piece will include MakesCapture.
    module MakesCapture 
      include Irreversible
      attr_reader :captured_piece
      
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

      # XOR out key for piece at from. XOR in the key for piece at to. XOR out key for @captured_piece at to.
      def hash(piece, from, to)
        from_to_key(piece, from, to) ^ Memory::psq_key(@captured_piece, to)
      end

      def mvv_lva(piece)  # Most valuable victim, least valuable attacker heuristic. Used for move ordering of captures.
        begin
          @mvv_lva ||= @captured_piece.class.value - piece.class.id
        rescue => err
          raise Memory::HashCollisionError
        end
      end

      def material_swing?
        true
      end
    end

    class RegularMove < MoveStrategy
      include Reversible
    end

    class KingMove < MoveStrategy
      include Reversible

      def make!(position, piece, from, to)
        super # call make! method inherited from MoveStrategy
        position.own_king_location = to  # update king location
      end

      def unmake!(position, piece, from, to)
        super # call unmake! method inherited from MoveStrategy
        position.own_king_location = from  # update king location
      end
    end

    class RegularCapture < MoveStrategy #  Stores captured piece for unmake purposes.
      include MakesCapture
    end

    class KingCapture < MoveStrategy
      include MakesCapture

      def make!(position, piece, from, to)
        super # call make! method mixed-in by MakesCapture
        position.own_king_location = to  # update king location
      end

      def unmake!(position, piece, from, to)
        super # call unmake! method mixed-in by MakesCapture
        position.own_king_location = from  # update king location
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
      include Irreversible  # regular pawn moves reset the halfmove clock
    end

    # Strategy used when a pawn makes a double move from its initial position at start of game.  This reders the 
    # moved pawn capturable via En Passant attack by another pawn for one turn.
    class EnPassantAdvance < MoveStrategy # Sets or removes the enp_target from position object.
      include Irreversible

      def make!(position, piece, from, to)
        super # call make! method inherited from MoveStrategy
        position.enp_target = to # Set enp_target to new target square. 
      end

      def hash(piece, from, to)
        from_to_key(piece, from, to) ^ Memory::enp_key(to)
      end
    end

    # Strategy used when a pawn moves onto the enemy back row, promoting it to a Queen.
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

      def print(piece, from, to)
        "#{piece} promotion #{from} to #{to}"
      end

      def hash(piece, from, to)
        Memory::psq_key(piece, from) ^ Memory::psq_key(@queen, to)
      end

      def material_swing?
        true
      end
    end

    # Strategy used when a pawn moves onto the enemy back row by capturing another piece.
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

      def print(piece, from, to)
        "#{piece} x #{@captured_piece} promotion #{from} to #{to}"
      end

      def hash(piece, from, to)
        Memory::psq_key(piece, from) ^ Memory::psq_key(@captured_piece, to) ^ Memory::psq_key(@queen, to)
      end

      def material_swing?
        true
      end
    end

    class Castle < MoveStrategy # Caches info on movement of the rook. King information is stored in the Move instance.
      include Reversible

      attr_accessor :rook, :rook_from, :rook_to
      def initialize(rook, rook_from, rook_to)
        @rook, @rook_from, @rook_to = rook, rook_from, rook_to
        @own_material, @enemy_material = 0, 0
      end

      def make!(position, piece, from, to)
        super # call make! method inherited from MoveStrategy
        make_relocate_piece(position, @rook, @rook_from, @rook_to)
        position.own_king_location = to
      end

      def unmake!(position, piece, from, to)
        super # call unmake! method inherited from MoveStrategy
        relocate_piece(position, @rook, @rook_to, @rook_from)
        position.own_king_location = from
      end

      def print(piece, from, to)
        "#{piece} castle #{from} to #{to}"
      end

      def hash(piece, from, to)
        from_to_key(piece, from, to) ^ from_to_key(@rook, @rook_from, @rook_to)
      end
    end

    # The Factory class provides a simplified interface for instantiating Move objects, 
    # hiding creation of strategy object instances from the client.
    class Factory  
      PROCS = { regular_move:           Proc.new { |*args| RegularMove.new },
                king_move:              Proc.new { |*args| KingMove.new },
                regular_capture:        Proc.new { |*args| RegularCapture.new(*args) },
                king_capture:           Proc.new { |*args| KingCapture.new(*args) },
                enp_capture:            Proc.new { |*args| EnPassantCapture.new(*args) },
                pawn_move:              Proc.new { |*args| PawnMove.new },
                enp_advance:            Proc.new { |*args| EnPassantAdvance.new },
                pawn_promotion:         Proc.new { |*args| PawnPromotion.new(*args) },
                pawn_promotion_capture: Proc.new { |*args| PawnPromotionCapture.new(*args) },
                castle:                 Proc.new { |*args| Castle.new(*args) } } 

      def self.build(piece, from, to, sym, *args)  # create a Move object containing the specified strategy.
        raise "no product strategy #{sym} available for Move::MoveFactory" unless PROCS[sym]
        Move.new(piece, from, to, PROCS[sym].call(*args)) 
      end
    end

  end
end






