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

    # Initial piece locations:
    WRQ_FROM = Location::get_location(2,2) # white rook queenside from square (a1)
    WK_FROM  = Location::get_location(2,6) # white king from square (e1)
    WRK_FROM = Location::get_location(2,9) # white rook kingside from square (h1)

    BRQ_FROM = Location::get_location(9,2) # black rook queenside from square (a8)
    BK_FROM  = Location::get_location(9,6) # black king from square (e8)
    BRK_FROM = Location::get_location(9,9) # black rook kingside from square (h8)

    WRQ_TO = Location::get_location(2,5) # white rook queenside to square (d1)
    WKQ_TO = Location::get_location(2,4) # white king queenside to square (c1)

    WRK_TO = Location::get_location(2,7) # white rook kingside to square (f1)
    WKK_TO = Location::get_location(2,8) # white king kingside to square (g1)

    BRQ_TO = Location::get_location(9,5) # black rook queenside to square (d8)
    BKQ_TO = Location::get_location(9,4) # black king queenside to square (c8)

    BRK_TO = Location::get_location(9,7) # black rook kingside to square (f8)
    BKK_TO = Location::get_location(9,8) # black king kingside to square (g8)

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
        if castle & C_WQ != 0b0
          if b.square_empty?(2,3) && b.square_empty?(2,4) && b.square_empty?(2,5)
            rook, king = pos.own_pieces[WRQ_FROM], pos.own_pieces[WK_FROM]
            castles << Move::Factory.build(king, WK_FROM, WKQ_TO, :castle, rook, WRQ_FROM, WRQ_TO) if king
          end 
        end
        if castle & C_WK != 0b0
          if b.square_empty?(2,7) && b.square_empty?(2,8)
            rook, king = pos.own_pieces[WRK_FROM], pos.own_pieces[WK_FROM]
            castles << Move::Factory.build(king, WK_FROM, WRK_TO, :castle, rook, WRK_FROM, WRK_TO) if king
          end
        end
      else
        if castle & C_BQ != 0b0
          if b.square_empty?(9,3) && b.square_empty?(9,4) && b.square_empty?(9,5)
            rook, king = pos.own_pieces[BRQ_FROM], pos.own_pieces[BK_FROM]
            castles << Move::Factory.build(king, BK_FROM, BKQ_TO, :castle, rook, BRQ_FROM, BRQ_TO) if king
          end 
        end
        if castle & C_BK != 0b0
          if b.square_empty?(9,7) && b.square_empty?(9,8)
            rook, king = pos.own_pieces[BRK_FROM], pos.own_pieces[BK_FROM]
            castles << Move::Factory.build(king, BK_FROM, BKK_TO, :castle, rook, BRK_FROM, BRK_TO) if king
          end
        end
      end
      return castles
    end

  end
end








