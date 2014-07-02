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
      attr_reader :piece, :from, :to, :strategy, :enp_target, :see

      def initialize(piece, from, to, strategy, see=nil)
        @piece, @from, @to, @strategy, @see = piece, from, to, strategy, see
      end

      def make!(position)
        # begin
          @enp_target, @castle_rights = position.enp_target, position.castle   # save old values for make/unmake
          position.enp_target = nil

          @strategy.make!(position, @piece, @from, @to)  # delegate to the strategy class.

        # rescue => err
        #   puts self.inspect
        #   raise Memory::HashCollisionError
        # end 
      end

      def unmake!(position)
        @strategy.unmake!(position, @piece, @from, @to)  # delegate to the strategy class.

        position.enp_target, position.castle = @enp_target, @castle_rights
      end

      def mvv_lva
        # @mvv_lva ||= @strategy.mvv_lva(@piece)
        @strategy.mvv_lva(@piece)
      end

      def see_score(pos)
        @see ||= Search::static_exchange_evaluation(pos.pieces, @from, @to, pos.side_to_move, pos.board.squares)
      end

      def hash # XOR out the old en-passant key, if any.
        @hash ||= @strategy.hash(@piece, @from, @to) ^ Memory::enp_key(@enp_target) ^ Memory::SIDE
      end

      def print
        @strategy.print(@piece, @from, @to)
      end

      def to_s
        "#{Pieces::ID_TO_STR[@piece]} #{Location::sq_to_s(@from)} #{Location::sq_to_s(@to)}"
      end

      def ==(other)
        return false if other.nil?
        @from == other.from && @to == other.to
      end

      def quiet?
        @strategy.quiet?
      end

      def promotion?
        @strategy.promotion?
      end

      def promoted_piece
        @strategy.promoted_piece
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
      attr_reader :promoted_piece

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
        "<#{self.class}>"
      end

      def hash(piece, from, to)
        from_to_key(piece, from, to)
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

      def promotion?
        false
      end
    end

    # The Halfmove Rule requires that all moves other than pawn moves and captures increment the halfmove clock.
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

      def print(piece, from, to)
        "#{piece} x #{@captured_piece} #{from} to #{to}"
      end

      def inspect
        "<#{self.class} <@captured_piece:#{@captured_piece}>>"
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
        return Pieces::VALUES[(@captured_piece&14)>>1] - piece
      end

      def quiet?
        false
      end
    end

    class RegularMove < MoveStrategy
      include Reversible
    end

    class RegularCapture < MoveStrategy #  Stores captured piece for unmake purposes.
      include MakesCapture
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

      def initialize(promoted_piece)
        @promoted_piece = promoted_piece
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

      def hash(piece, from, to) # XOR out piece at from.  XOR in @queen at to.
        Memory::psq_key(piece, from) ^ Memory::psq_key(@promoted_piece, to)
      end

      def quiet?
        false
      end

      def promotion?
        true
      end
    end

    # Strategy used when a pawn moves onto the enemy back row by capturing another piece.
    class PawnPromotionCapture < MoveStrategy      
      include MakesCapture

      def initialize(promoted_piece, captured_piece)  
        @promoted_piece, @captured_piece = promoted_piece, captured_piece
      end

      def make!(position, piece, from, to)# do not add PST delta for this move, since the moved piece is replaced by a new queen.
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

      def print(piece, from, to)
        "#{piece} x #{@captured_piece} promotion #{from} to #{to}"
      end

      def hash(piece, from, to) # XOR out piece at from. XOR out @captured_piece at to.  XOR in @queen at to.
        Memory::psq_key(piece, from) ^ Memory::psq_key(@captured_piece, to) ^ Memory::psq_key(@promoted_piece, to)
      end

      def promotion?
        true
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

      def inspect
        "<#{self.class} <@rook:#{@rook}> <@rook_from:#{@rook_from}> <@rook_to:#{@rook_to}>>"
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
    #
    #   1.  The build() method creates a move object using the strategy specified by the client.
    #   2.  The build_move() method chooses the correct strategy to use, and returns the appropriate move object.               
    class Factory                                                                             # Args:
      PROCS = { regular_move:           Proc.new { |*args| RegularMove.new                },  
                regular_capture:        Proc.new { |*args| RegularCapture.new(*args)      },  # captured_piece
                castle:                 Proc.new { |*args| Castle.new(*args)              },  # rook, rook_from, rook_to
                enp_capture:            Proc.new { |*args| EnPassantCapture.new(*args)    },  # captured_piece, enp_target
                pawn_move:              Proc.new { |*args| PawnMove.new                   },  
                enp_advance:            Proc.new { |*args| EnPassantAdvance.new           },
                pawn_promotion:         Proc.new { |*args| PawnPromotion.new(*args)       },  # promoted_piece
                pawn_promotion_capture: Proc.new { |*args| PawnPromotionCapture.new(*args)} } # promoted_piece, captured_piece
      private_constant :PROCS
      
      # Factory interface
      
      def self.build_move(pos, from, to)
        piece = pos.board[from]
        type = Pieces::type(piece)
        case type
        when :P then build_pawn_move(pos, piece, from, to)
        when :K then build_king_move(pos, piece, from, to)
        else build_regular_move(pos, piece, from, to)
        end
      end

      def self.build(piece, from, to, sym, *args)  # create a Move object containing the specified strategy.
        raise "no product strategy #{sym} available for Move::MoveFactory" unless PROCS[sym]
        move = Move.new(piece, from, to, PROCS[sym].call(*args)) 
        puts move.inspect
        puts move.strategy.class
        move
      end

      private

      def self.build_pawn_move(pos, piece, from, to)
        if Pieces::ENEMY_BACK_ROW[pos.side_to_move] == pos.board.row(to)
          build_promotion(pos, piece, from, to)
        elsif Pieces::PAWN_START_ROW[pos.side_to_move] == pos.board.row(from) && 
              pos.board.manhattan_distance(from, to) == 2 && pos.board.column(from) == pos.board.column(to)
          build(piece, from, to, :enp_advance)
        else
          if pos.pieces.enemy?(to, pos.side_to_move)
            build(piece, from, to, :regular_capture, pos.board[to])
          elsif pos.enp_target && pos.board.manhattan_distance(from, to) == 2 &&
                pos.board.manhattan_distance(pos.enp_target, from) == 1 &&
                pos.board.column(pos.enp_target) == pos.board.column(to)
            build(piece, from, to, :enp_capture, pos.board[pos.enp_target], pos.enp_target)            
          else
            build(piece, from, to, :pawn_move)
          end
        end
      end

      def self.build_promotion(pos, piece, from, to)
        promoted_piece = pos.side_to_move == :w ? WQ_ID : BQ_ID 
        if pos.pieces.enemy?(to, pos.side_to_move)
          build(piece, from, to, :pawn_promotion_capture, promoted_piece, pos.board[to])
        else
          build(piece, from, to, :pawn_promotion, promoted_piece)
        end
      end

      def self.build_king_move(pos, piece, from, to)
        if pos.board.manhattan_distance(from, to) == 2 && pos.board.row(to) == pos.board.row(from)
          build_castle(pos, piece, from, to)
        else
          build_regular_move(pos, piece, from, to)
        end
      end

      # Squares involved in castling:
      WRQ_FROM = Location::SQUARES[:a1] # white rook queenside from square
      WRQ_TO = Location::SQUARES[:d1] # white rook queenside to square

      WRK_FROM = Location::SQUARES[:h1] # white rook kingside from square
      WRK_TO = Location::SQUARES[:f1] # white rook kingside to square

      BRQ_FROM = Location::SQUARES[:a8] # black rook queenside from square
      BRQ_TO = Location::SQUARES[:d8] # black rook queenside to square

      BRK_FROM = Location::SQUARES[:h8] # black rook kingside from square
      BRK_TO = Location::SQUARES[:f8] # black rook kingside to square

      def self.build_castle(pos, piece, from, to)
        if pos.side_to_move == :w  
          if to > from
            build(piece, from, to, :castle, Pieces::PIECE_ID[:wR], WRK_FROM, WRK_TO)
          else
            build(piece, from, to, :castle, Pieces::PIECE_ID[:wR], WRQ_FROM, WRQ_TO)
          end
        else
          if to > from
            build(piece, from, to, :castle, Pieces::PIECE_ID[:bR], BRK_FROM, BRK_TO)
          else
            build(piece, from, to, :castle, Pieces::PIECE_ID[:bR], BRQ_FROM, BRQ_TO)
          end
        end
      end

      def self.build_regular_move(pos, piece, from, to)
        if pos.pieces.enemy?(to, pos.side_to_move)
          build(piece, from, to, :regular_capture, pos.board[to])
        else
          build(piece, from, to, :regular_move)
        end
      end

    end

  end
end






