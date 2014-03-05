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

    # Castling rights
    C_WQ = 0b1000  # White castle queen side
    C_WK = 0b0100  # White castle king side
    C_BQ = 0b0010  # Black castle queen side
    C_BK = 0b0001  # Black castle king side
    C_NONE = 0b0000 # no castle availability

    # Module interface

    def self.make!(position, move) # Mutates position by making the specified move. 
      move.make!(position)        
      set_castle_flag(position, move)  # Old castle rights are cached in move for unmake.
      flip(position, move)
    end

    def self.unmake!(position, move) # Mutates position by reversing the specified move.  
      flip(position, move)          
      move.unmake!(position)
    end

    def self.flip(pos, move)
      if pos.side_to_move == :w
        pos.side_to_move, pos.enemy = :b, :w
      else
        pos.side_to_move, pos.enemy = :w, :b
      end
      update_hash(pos, move)
    end

    def self.update_hash(pos, move)
      pos.hash ^= move.hash ^ Memory::side_key
    end

    def self.flip_null(pos, enp_target)
      if pos.side_to_move == :w
        pos.side_to_move, pos.enemy = :b, :w
      else
        pos.side_to_move, pos.enemy = :w, :b
      end
      pos.hash ^= Memory::side_key ^ Memory::enp_key(enp_target)
    end

    WRQ_INIT = Location::get_location(2,2) # a1
    WK_INIT = Location::get_location(2,6)  # e1
    WRK_INIT = Location::get_location(2,9) # h1
    BRQ_INIT = Location::get_location(9,2) # a8
    BK_INIT = Location::get_location(9,6)  # e8
    BRK_INIT = Location::get_location(9,9) # h8

    WATCH = { WRQ_INIT => Proc.new { |pos| pos.castle &= ~C_WQ }, 
              WK_INIT => Proc.new { |pos| pos.castle &= ~(C_WK|C_WQ) },
              WRK_INIT => Proc.new { |pos| pos.castle &= ~C_WK },
              BRQ_INIT => Proc.new { |pos| pos.castle &= ~C_BQ },
              BK_INIT => Proc.new { |pos| pos.castle &= ~(C_BK|C_BQ) },
              BRK_INIT => Proc.new { |pos| pos.castle &= ~C_BK } }

    def self.set_castle_flag(position, move)
      WATCH[move.from].call(position) if WATCH[move.from]
      WATCH[move.to].call(position) if WATCH[move.to]
    end

    def self.get_castles(pos)
      castle, b = pos.castle, pos.board
      castles = []
      if pos.side_to_move == :w
        if castle & C_WQ != 0b0
          if b.square_empty?(2,3) && b.square_empty?(2,4) && b.square_empty?(2,5)
            # also need to check if enemy controls these squares.
            rook_from, rook_to = WRQ_INIT, Location::get_location(2,5)
            rook = pos.own_pieces[rook_from]
            king_from, king_to = WK_INIT, Location::get_location(2,4)
            king = pos.own_pieces[king_from]
            castles << Move::Factory.build(king, king_from, king_to, :castle, rook, rook_from, rook_to) if king
          end 
        end
        if castle & C_WK != 0b0
          if b.square_empty?(2,7) && b.square_empty?(2,8)
            # also need to check if enemy controls these squares.
            rook_from, rook_to = WRK_INIT, Location::get_location(2,7)
            rook = pos.own_pieces[rook_from]
            king_from, king_to = WK_INIT, Location::get_location(2,8)
            king = pos.own_pieces[king_from]
            castles << Move::Factory.build(king, king_from, king_to, :castle, rook, rook_from, rook_to) if king
          end
        end
      else
        if castle & C_BQ != 0b0
          if b.square_empty?(9,3) && b.square_empty?(9,4) && b.square_empty?(9,5)
            # also need to check if enemy controls these squares.
            rook_from, rook_to = BRQ_INIT, Location::get_location(9,5)
            rook = pos.own_pieces[rook_from]
            king_from, king_to = BK_INIT, Location::get_location(9,4)
            king = pos.own_pieces[king_from]
            castles << Move::Factory.build(king, king_from, king_to, :castle, rook, rook_from, rook_to) if king
          end 
        end
        if castle & C_BK != 0b0
          if b.square_empty?(9,7) && b.square_empty?(9,8)
            # also need to check if enemy controls these squares.
            rook_from, rook_to = BRK_INIT, Location::get_location(9,7)
            rook = pos.own_pieces[rook_from]
            king_from, king_to = BK_INIT, Location::get_location(9,8)
            king = pos.own_pieces[king_from]
            castles << Move::Factory.build(king, king_from, king_to, :castle, rook, rook_from, rook_to) if king
          end
        end
      end
      return castles
    end

  end
end








