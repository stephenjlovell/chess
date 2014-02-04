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
  module MoveGen

    # Castling rights
    C_WQ = 0b1000  # White castle queen side
    C_WK = 0b0100  # White castle king side
    C_BQ = 0b0010  # Black castle queen side
    C_BK = 0b0001  # Black castle king side

    class MoveList  # Notional place to store, organize, and sort moves more easily.
      attr_accessor :captures, :regular_moves, :castles, :checks

      # Generate moves by category of move, then append categories together.
      # use arr.uniq{ |m| m.hash } to eliminate duplicate moves.

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
      move.make!(position)        
      set_castle_flag(position, move)  # Old castle flag is stored in move for unmake.
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
      pos.hash ^= move.hash ^ Memory::side_key
    end

    WATCH = { Location::get_location(2,2) => Proc.new { |pos| pos.castle &= ~C_WQ },
              Location::get_location(2,6) => Proc.new { |pos| pos.castle &= ~(C_WK|C_WQ) },
              Location::get_location(2,8) => Proc.new { |pos| pos.castle &= ~C_WK },
              Location::get_location(9,2) => Proc.new { |pos| pos.castle &= ~C_BQ },
              Location::get_location(9,6) => Proc.new { |pos| pos.castle &= ~(C_BK|C_BQ) },
              Location::get_location(9,8) => Proc.new { |pos| pos.castle &= ~C_BK } }

    def self.set_castle_flag(position, move)
      WATCH[move.from].call(position) if WATCH[move.from]
      WATCH[move.to].call(position) if WATCH[move.to]
    end

    def self.get_castles(pos)
      castle, b = pos.castle, pos.board
      castles = []
      if pos.side_to_move == :w
        if castle & C_WQ
          if b.square_empty?(2,3) && b.square_empty?(2,4) && b.square_empty?(2,5)
            # also need to check if enemy controls these squares.
            rook_from, rook_to = Location::get_location(2,2), Location::get_location(2,5)
            rook = pos.active_pieces[rook_from]
            king_from, king_to = Location::get_location(2,6), Location::get_location(2,4)
            king = pos.active_pieces[king_from]
            castles << Move::Factory.build(king, king_from, king_to, :castle, rook, rook_from, rook_to) if king
          end 
        end
        if castle & C_WK
          if b.square_empty?(2,7) && b.square_empty?(2,8)
            # also need to check if enemy controls these squares.
            rook_from, rook_to = Location::get_location(2,9), Location::get_location(2,7)
            rook = pos.active_pieces[rook_from]
            king_from, king_to = Location::get_location(2,6), Location::get_location(2,8)
            king = pos.active_pieces[king_from]
            castles << Move::Factory.build(king, king_from, king_to, :castle, rook, rook_from, rook_to) if king
          end
        end
      else
        if castle & C_BQ
          if b.square_empty?(9,3) && b.square_empty?(9,4) && b.square_empty?(9,5)
            # also need to check if enemy controls these squares.
            rook_from, rook_to = Location::get_location(9,2), Location::get_location(9,5)
            rook = pos.active_pieces[rook_from]
            king_from, king_to = Location::get_location(9,6), Location::get_location(9,4)
            king = pos.active_pieces[king_from]
            castles << Move::Factory.build(king, king_from, king_to, :castle, rook, rook_from, rook_to) if king
          end 
        end
        if castle & C_BK
          if b.square_empty?(9,7) && b.square_empty?(9,8)
            # also need to check if enemy controls these squares.
            rook_from, rook_to = Location::get_location(9,9), Location::get_location(9,7)
            rook = pos.active_pieces[rook_from]
            king_from, king_to = Location::get_location(9,6), Location::get_location(9,8)
            king = pos.active_pieces[king_from]
            castles << Move::Factory.build(king, king_from, king_to, :castle, rook, rook_from, rook_to) if king
          end
        end
      end
      return castles
    end

  end
end








