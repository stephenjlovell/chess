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
          # position.own_tropism += @strategy.own_tropism(position, @piece, @from, @to)
          # position.enemy_tropism += @strategy.enemy_tropism(position, @piece, @from, @to)

          @strategy.make!(position, @piece, @from, @to)  # delegate to the strategy class.

          # position.own_material += @strategy.own_material(position, @piece, @from, @to)
          # position.enemy_material += @strategy.enemy_material(position, @piece, @from, @to)
        rescue => err
          puts self.inspect
          raise
        #   raise Memory::HashCollisionError
        end 
      end

      def unmake!(position)
        # position.own_material -= @strategy.own_material(position, @piece, @from, @to)
        # position.enemy_material -= @strategy.enemy_material(position, @piece, @from, @to)

        @strategy.unmake!(position, @piece, @from, @to)  # delegate to the strategy class.

        # position.own_tropism -= @strategy.own_tropism(position, @piece, @from, @to)
        # position.enemy_tropism -= @strategy.enemy_tropism(position, @piece, @from, @to)
        position.enp_target, position.castle = @enp_target, @castle_rights
      end

      def mvv_lva
        @mvv_lva ||= @strategy.mvv_lva(@piece)
      end

      def see_score(position)
        # puts "getting SEE score"
        # @see ||= Search::see(position, @to)
        @see ||= Search::static_exchange_evaluation(@from, @to, position.side_to_move, position.board)
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
        Location::get_location(@from).to_s + Location::get_location(@to).to_s
      end

      def ==(other)
        # may be able to replace this with single comparison
        return false if other.nil?
        @from == other.from && @to == other.to
      end

      def quiet?
        @strategy.quiet?
      end

      def inspect
        "<Chess::Move::Move <@piece:#{Pieces::ID_TO_STR[@piece]}><@from:#{Location::sq_to_s(@from)}> " + 
        "<@to:#{Location::sq_to_s(@to)}><@enp_target:#{@enp_target}><@see:#{@see}><@strategy:#{@strategy.inspect}>>"
      end
    end

    # The MoveStrategy class provides a generic template and shared behavior for each move strategy. Concrete strategy 
    # classes include either the Reversible or Irreversible module.  If the concrete strategy class captures an enemy piece, 
    # the strategy class will include the MakesCapture module.

    class MoveStrategy  
      def initialize
      end

      def make!(position, piece, from, to)
        relocate_piece(position, piece, from, to)
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

      def own_material(position, piece, from, to)
        @own_material ||= Evaluation::pst_value(position, piece, to)-Evaluation::pst_value(position, piece, from)
      end

      def enemy_material(position, piece, from, to)
        @enemy_material ||= 0
      end

      def own_tropism(pos, piece, from, to) 
        @own_tropism ||= Tropism::get_bonus(piece, to, pos.enemy_king_location) 
                       - Tropism::get_bonus(piece, from, pos.enemy_king_location) 
      end

      def enemy_tropism(pos, piece, from, to) 
        @enemy_tropism ||= 0
      end

      def relocate_piece(position, piece, from, to)
        position.pieces.relocate_piece(piece, from, to) # relocate piece on bitboard.
        position.board[from] = 0                        # relocate piece on square-centric board.
        position.board[to] = piece
      end

      # XOR out the key for piece at from, and XOR in the key for piece at to.
      def from_to_key(piece, from, to)
        Memory::psq_key(piece, from) ^ Memory::psq_key(piece, to)
      end

      def quiet?
        true
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
        @captured_piece = captured_piece
      end

      def make!(position, piece, from, to)
        relocate_piece(position, piece, from, to)
        make_clock_adjustment(position)
        position.pieces.remove_square(@captured_piece, to)  # Remove enemy piece from bitboard.
      end

      def unmake!(position, piece, from, to)
        relocate_piece(position, piece, to, from)
        unmake_clock_adjustment(position)
        position.board[to] = @captured_piece
        position.pieces.add_square(@captured_piece, to) # Replace stored enemy piece on bitboard
      end

      def enemy_material(position, piece, from, to)
        @enemy_material ||= -Evaluation::adjusted_value(position, @captured_piece, to)
      end

      def enemy_tropism(pos, piece, from, to)
        @enemy_tropism ||= -Tropism::get_bonus(@captured_piece, to, pos.own_king_location) 
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
        begin
        from_to_key(piece, from, to) ^ Memory::psq_key(@captured_piece, to)
      rescue
        puts piece
        puts "captured piece: #{@captured_piece}"
        raise
      end
      end

      def mvv_lva(piece)  # Most valuable victim, least valuable attacker heuristic. Used for move ordering of captures.
        # begin
        return Pieces::VALUES[(@captured_piece>>1)&7] - piece
        # rescue => err
        #   raise Memory::HashCollisionError
        # end
      end

      def quiet?
        false
      end
    end

    class RegularMove < MoveStrategy
      include Reversible
    end

    class KingMove < MoveStrategy
      include Reversible

      def own_tropism(pos, piece, from, to)
        @own_tropism ||= 0
      end

      def enemy_tropism(pos, piece, from, to)  # ideally, this should be independent of make/unmake timing.
        @enemy_tropism ||= Evaluation::king_tropism(pos, pos.enemy, to) - pos.enemy_tropism
      end
    end

    class RegularCapture < MoveStrategy #  Stores captured piece for unmake purposes.
      include MakesCapture
    end

    class KingCapture < MoveStrategy
      include MakesCapture

      def own_tropism(pos, piece, from, to)
        @own_tropism ||= 0
      end

      def enemy_tropism(pos, piece, from, to) # Must be called before strategy.make!
        @enemy_tropism ||= Evaluation::king_tropism(pos, pos.enemy, to) - pos.enemy_tropism
                         - Tropism::get_bonus(@captured_piece, to, to) 
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
        position.board[@enp_target] = 0
        position.pieces.remove_square(@captured_piece, @enp_target) # Remove stored enemy piece on bitboard
      end

      def unmake!(position, piece, from, to)
        relocate_piece(position, piece, to, from)
        unmake_clock_adjustment(position)
        position.board[@enp_target] = @captured_piece
        position.pieces.add_square(@captured_piece, @enp_target) # Replace stored enemy piece on bitboard
      end

      def enemy_material(position, piece, from, to)
        @enemy_material ||= -Evaluation::adjusted_value(position, @captured_piece, @enp_target)
      end

      def enemy_tropism(pos, piece, from, to)
        @enemy_tropism ||= -Tropism::get_bonus(@captured_piece, @enp_target, pos.own_king_location) 
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
        from_to_key(piece, from, to) ^ Memory::enp_key(to) # XOR in the hash key for the new en-passant target.
      end
    end

    WQ_ID = Pieces::PIECE_ID[:wQ]
    BQ_ID = Pieces::PIECE_ID[:bQ]

    # Strategy used when a pawn moves onto the enemy back row, promoting it to a Queen.
    class PawnPromotion < MoveStrategy # Stores the existing pawn in move object and places a new Queen.


      include Irreversible
      def initialize(side_to_move)
        @promoted_piece = side_to_move == :w ? WQ_ID : BQ_ID  # piece_id constants for queens.
      end

      def make!(position, piece, from, to)
        # do not add PST delta for this move, since the moved piece is replaced by a new queen.
        make_clock_adjustment(position)
        position.board[from] = 0
        position.board[to] = @promoted_piece
        position.pieces.remove_square(piece, from)
        position.pieces.add_square(@promoted_piece, to)
      end

      def unmake!(position, piece, from, to)
        unmake_clock_adjustment(position)
        position.board[from] = piece
        position.board[to] = 0
        position.pieces.add_square(piece, from)
        position.pieces.remove_square(@promoted_piece, to)
      end


      def print(piece, from, to)
        "#{piece} promotion #{from} to #{to}"
      end

      def own_material(position, piece, from, to)
        @own_material ||= Evaluation::adjusted_value(position, @promoted_piece, to)
                        - Evaluation::adjusted_value(position, piece, from)
      end

      def own_tropism(pos, piece, from, to)
        @own_tropism ||= Tropism::get_bonus(@promoted_piece, to, pos.enemy_king_location) 
                       - Tropism::get_bonus(piece, from, pos.enemy_king_location)
      end

      def hash(piece, from, to) # XOR out piece at from.  XOR in @queen at to.
        Memory::psq_key(piece, from) ^ Memory::psq_key(@promoted_piece, to)
      end

      def quiet?
        false
      end
    end

    # Strategy used when a pawn moves onto the enemy back row by capturing another piece.
    class PawnPromotionCapture < MoveStrategy      
      include MakesCapture

      def initialize(captured_piece)  
        @captured_piece = captured_piece
        @promoted_piece = (captured_piece & 1) == 0 ? WQ_ID : BQ_ID  # piece_id constants for queens.
      end

      def make!(position, piece, from, to)
        # do not add PST delta for this move, since the moved piece is replaced by a new queen.
        make_clock_adjustment(position)
        position.board[from] = 0
        position.board[to] = @promoted_piece
        position.pieces.remove_square(piece, from)
        position.pieces.remove_square(@captured_piece, to)
        position.pieces.add_square(@promoted_piece, to)
      end

      def unmake!(position, piece, from, to)
        unmake_clock_adjustment(position)
        position.board[from] = piece
        position.board[to] = @captured_piece
        position.pieces.add_square(piece, from)
        position.pieces.add_square(@captured_piece, to)
        position.pieces.remove_square(@promoted_piece, to)
      end

      def own_material(position, piece, from, to)
        @own_material ||= Evaluation::adjusted_value(position, @promoted_piece, to)
                        - Evaluation::adjusted_value(position, piece, from)
      end

      def own_tropism(pos, piece, from, to)
        @own_tropism ||= Tropism::get_bonus(@promoted_piece, to, pos.enemy_king_location) 
                       - Tropism::get_bonus(piece, from, pos.enemy_king_location)
      end

      def print(piece, from, to)
        "#{piece} x #{@captured_piece} promotion #{from} to #{to}"
      end

      def hash(piece, from, to) # XOR out piece at from. XOR out @captured_piece at to.  XOR in @queen at to.
        Memory::psq_key(piece, from) ^ Memory::psq_key(@captured_piece, to) ^ Memory::psq_key(@promoted_piece, to)
      end

    end

    class Castle < MoveStrategy # Caches info on movement of the rook. King information is stored in the Move instance.
      include Reversible
      attr_accessor :rook, :rook_from, :rook_to

      def initialize(rook, rook_from, rook_to)
        @rook, @rook_from, @rook_to = rook, rook_from, rook_to
      end

      def make!(position, piece, from, to)
        super # call make! method inherited from MoveStrategy
        relocate_piece(position, @rook, @rook_from, @rook_to)
      end

      def unmake!(position, piece, from, to)
        super # call unmake! method inherited from MoveStrategy
        relocate_piece(position, @rook, @rook_to, @rook_from)
      end

      def own_material(position, piece, from, to)
        @own_material ||= Evaluation::pst_value(position, piece, to)
                        - Evaluation::pst_value(position, piece, from)
                        + Evaluation::pst_value(position, @rook, @rook_to)
                        - Evaluation::pst_value(position, @rook, @rook_from)
      end

      def own_tropism(pos, piece, from, to)
        @own_tropism ||= Tropism::get_bonus(@rook, @rook_to, pos.enemy_king_location) 
                       - Tropism::get_bonus(@rook, @rook_from, pos.enemy_king_location)
      end

      def enemy_tropism(pos, piece, from, to) # recalculation of enemy tropism is caused by king movement.
        @enemy_tropism ||= Evaluation::king_tropism(pos, pos.enemy, to) - pos.enemy_tropism
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
      PROCS = { regular_move:           Proc.new { |*args| RegularMove.new                },
                regular_capture:        Proc.new { |*args| RegularCapture.new(*args)      },
                castle:                 Proc.new { |*args| Castle.new(*args)              },
                king_move:              Proc.new { |*args| KingMove.new                   },
                king_capture:           Proc.new { |*args| KingCapture.new(*args)         },
                enp_capture:            Proc.new { |*args| EnPassantCapture.new(*args)    },
                pawn_move:              Proc.new { |*args| PawnMove.new                   },
                enp_advance:            Proc.new { |*args| EnPassantAdvance.new           },
                pawn_promotion:         Proc.new { |*args| PawnPromotion.new(*args)       },
                pawn_promotion_capture: Proc.new { |*args| PawnPromotionCapture.new(*args)} } 

      def self.build(piece, from, to, sym, *args)  # create a Move object containing the specified strategy.
        raise "no product strategy #{sym} available for Move::MoveFactory" unless PROCS[sym]
        Move.new(piece, from, to, PROCS[sym].call(*args)) 
      end
    end

  end
end






