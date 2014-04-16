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
  module MoveGen

    # The MoveGen module handles the incremental update of the game state by making and unmaking moves, 
    # and by updating the hash key, side to move, and castle rights for the position.  Each make! operation is 
    # reversible via unmake!

    def self.make!(position, move) 
      move.make!(position)  # Delegate most of the heavy lifting to the Move class.
      set_castle_flag(position, move)  # Old castle rights are cached in move for unmake.
      flip(position, move)
    end

    def self.unmake!(position, move)
      flip(position, move) # Unmake operations are done relative to original side to move, so update side to move first.         
      move.unmake!(position) # Delegate most of the heavy lifting to the Move class.
    end

    # Updates the side to move and hash key for position.
    def self.flip(position, move)
      if position.side_to_move == :w
        position.side_to_move, position.enemy = :b, :w
      else
        position.side_to_move, position.enemy = :w, :b
      end
      position.hash ^= move.hash
    end

    # Updates the side to move and hash key as if the current side forfeited a turn.  Used for the Null Move Pruning
    # heuristic during Search.
    def self.flip_null(position, enp_target)
      if position.side_to_move == :w
        position.side_to_move, position.enemy = :b, :w
      else
        position.side_to_move, position.enemy = :w, :b
      end
      position.hash ^= Memory::SIDE ^ Memory::enp_key(enp_target)
    end

    # Castling rights:
    C_WQ = 0b1000  # White castle queen side
    C_WK = 0b0100  # White castle king side
    C_BQ = 0b0010  # Black castle queen side
    C_BK = 0b0001  # Black castle king side

    # Squares involved in castling:
    WRQ_FROM = Location::get_location_by_symbol(:a1) # white rook queenside from square
    WK_FROM  = Location::get_location_by_symbol(:e1) # white king from square
    WRK_FROM = Location::get_location_by_symbol(:h1) # white rook kingside from square 
    BRQ_FROM = Location::get_location_by_symbol(:a8) # black rook queenside from square 
    BK_FROM  = Location::get_location_by_symbol(:e8) # black king from square 
    BRK_FROM = Location::get_location_by_symbol(:h8) # black rook kingside from square 
    WRQ_TO   = Location::get_location_by_symbol(:d1) # white rook queenside to square 
    WKQ_TO   = Location::get_location_by_symbol(:c1) # white king queenside to square 
    WRK_TO   = Location::get_location_by_symbol(:f1) # white rook kingside to square 
    WKK_TO   = Location::get_location_by_symbol(:g1) # white king kingside to square 
    BRQ_TO   = Location::get_location_by_symbol(:d8) # black rook queenside to square 
    BKQ_TO   = Location::get_location_by_symbol(:c8) # black king queenside to square 
    BRK_TO   = Location::get_location_by_symbol(:f8) # black rook kingside to square 
    BKK_TO   = Location::get_location_by_symbol(:g8) # black king kingside to square 
 
    # Bitwise operations for updating castling rights.
    WATCH = { WRQ_FROM => Proc.new { |pos| pos.castle &= ~C_WQ }, 
              WK_FROM  => Proc.new { |pos| pos.castle &= ~(C_WK|C_WQ) },
              WRK_FROM => Proc.new { |pos| pos.castle &= ~C_WK },
              BRQ_FROM => Proc.new { |pos| pos.castle &= ~C_BQ },
              BK_FROM  => Proc.new { |pos| pos.castle &= ~(C_BK|C_BQ) },
              BRK_FROM => Proc.new { |pos| pos.castle &= ~C_BK } }

    # Whenever a king or rook moves off its initial square or is captured, update castle rights via the procedure
    # associated with that initial square.
    def self.set_castle_flag(position, move)
      WATCH[move.from].call(position) if WATCH[move.from]
      WATCH[move.to].call(position) if WATCH[move.to]
    end


    # Generate any legal castling moves available given castling rights for pos.
    def self.get_castles(pos)
      castle, b = pos.castle, pos.board
      castles = []
      if pos.side_to_move == :w
        if castle & C_WQ != 0
          if b.square_empty?(2,3) && b.square_empty?(2,4) && b.square_empty?(2,5)
            rook, king = pos.own_pieces[WRQ_FROM], pos.own_pieces[WK_FROM]
            castles << Move::Factory.build(king, WK_FROM, WKQ_TO, :castle, rook, WRQ_FROM, WRQ_TO) if king
          end 
        end
        if castle & C_WK != 0
          if b.square_empty?(2,7) && b.square_empty?(2,8)
            rook, king = pos.own_pieces[WRK_FROM], pos.own_pieces[WK_FROM]
            castles << Move::Factory.build(king, WK_FROM, WRK_TO, :castle, rook, WRK_FROM, WRK_TO) if king
          end
        end
      else
        if castle & C_BQ != 0
          if b.square_empty?(9,3) && b.square_empty?(9,4) && b.square_empty?(9,5)
            rook, king = pos.own_pieces[BRQ_FROM], pos.own_pieces[BK_FROM]
            castles << Move::Factory.build(king, BK_FROM, BKQ_TO, :castle, rook, BRQ_FROM, BRQ_TO) if king
          end 
        end
        if castle & C_BK != 0
          if b.square_empty?(9,7) && b.square_empty?(9,8)
            rook, king = pos.own_pieces[BRK_FROM], pos.own_pieces[BK_FROM]
            castles << Move::Factory.build(king, BK_FROM, BKK_TO, :castle, rook, BRK_FROM, BRK_TO) if king
          end
        end
      end
      return castles
    end


    def self.get_non_captures(pos, moves)
      pieces, occupied = pos.own_pieces, pos.occupied
      Pieces::send_to_each(:get_non_captures, pos, moves, pieces, occupied)

    end

    def self.get_captures(pos, moves)
      pieces, occupied, enemy = pos.own_pieces, pos.occupied, pos.enemy_pieces
      Pieces::send_to_each(:get_captures, pos, moves, pieces, occupied, enemy)
    end

    def self.get_checks(pos, moves)

    end

    def self.get_check_evasions(pos, moves)

    end


  end
end








