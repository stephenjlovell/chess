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
    begin
      if position.side_to_move == :w
        position.side_to_move, position.enemy = :b, :w
      else
        position.side_to_move, position.enemy = :w, :b
      end
      position.hash ^= move.hash
    rescue
      position.board.print
      puts move.inspect
      raise
    end
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
    WRQ_FROM = Location::SQUARES[:a1] # white rook queenside from square
    WK_FROM  = Location::SQUARES[:e1] # white king from square
    WRK_FROM = Location::SQUARES[:h1] # white rook kingside from square 
    BRQ_FROM = Location::SQUARES[:a8] # black rook queenside from square 
    BK_FROM  = Location::SQUARES[:e8] # black king from square 
    BRK_FROM = Location::SQUARES[:h8] # black rook kingside from square 
    WRQ_TO   = Location::SQUARES[:d1] # white rook queenside to square 
    WKQ_TO   = Location::SQUARES[:c1] # white king queenside to square 
    WRK_TO   = Location::SQUARES[:f1] # white rook kingside to square 
    WKK_TO   = Location::SQUARES[:g1] # white king kingside to square 
    BRQ_TO   = Location::SQUARES[:d8] # black rook queenside to square 
    BKQ_TO   = Location::SQUARES[:c8] # black king queenside to square 
    BRK_TO   = Location::SQUARES[:f8] # black rook kingside to square 
    BKK_TO   = Location::SQUARES[:g8] # black king kingside to square 
 
    # Bitwise operations for updating castling rights.
    WATCH = { WRQ_FROM => Proc.new { |pos| pos.castle &= ~C_WQ          }, 
              WK_FROM  => Proc.new { |pos| pos.castle &= ~(C_WK|C_WQ)   },
              WRK_FROM => Proc.new { |pos| pos.castle &= ~C_WK          },
              BRQ_FROM => Proc.new { |pos| pos.castle &= ~C_BQ          },
              BK_FROM  => Proc.new { |pos| pos.castle &= ~(C_BK|C_BQ)   },
              BRK_FROM => Proc.new { |pos| pos.castle &= ~C_BK          } }
              
    # Whenever a king or rook moves off its initial square or is captured, update castle rights via the procedure
    # associated with that initial square.
    def self.set_castle_flag(position, move)
      WATCH[move.from].call(position) if WATCH[move.from]
      WATCH[move.to].call(position)   if WATCH[move.to]
    end



  end
end








