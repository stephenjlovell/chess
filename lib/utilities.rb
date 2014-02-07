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

# This file is for Application-level constants and helper methods

module Chess

  # global variables:
  $INF = 1.0/0.0
  $tt = nil  # global access to transposition table instance.

  ENEMY_BACK_ROW = { w: 9, b: 2 }

  FLIP_COLOR = { w: :b, b: :w }

  
  module Notation # supports translation to and from long algebraic chess notation.

    class InvalidMoveError < StandardError

    end


    def self.move_to_str(move)
      move.to_s
    end

    def self.str_to_move(pos, str) # create a move object from long algebraic chess notation (used by UCI).
      # Valid examples:  e2e4, e7e5, e1g1 (white short castling), e7e8q (for promotion)
      from = Location::string_to_location(str[0..1])
      to = Location::string_to_location(str[2..3])
      raise InvalidMoveError, 'invalid square coordinates given' if from.nil? || to.nil?

      piece, enemy = pos.own_pieces[from], pos.enemy_pieces[to]
      raise InvalidMoveError, "no piece available at square #{from}" if piece.nil?

      own_type = piece.class.type
      if enemy # move is a capture, but not an en-passant capture.
        if own_type== :K
          return Move::Factory.build(piece, from, to, :king_capture, enemy)
        elsif own_type == :P && to.r == ENEMY_BACK_ROW[piece.color]
          return Move::Factory.build(piece, from, to, :pawn_promotion_capture, enemy) # implicit pawn promotion
        else
          return Move::Factory.build(piece, from, to, :regular_capture, enemy)
        end
      else
        case own_type
        when :P
          if from + [1,0] == to || from + [-1,0] == to
            if to.r == ENEMY_BACK_ROW[piece.color]
              return Move::Factory.build(piece, from, to, :pawn_promotion) 
            else
              return Move::Factory.build(piece, from, to, :pawn_move)     
            end
          elsif from + [2,0] == to || from + [-2,0] == to
            return Move::Factory.build(piece, from, to, :enp_advance)    
          else
            target = pos.enp_target
            enemy = pos.enemy_pieces[target]
            if enemy.nil? || (from + [0,1] != target && from + [0,-1] != target)
              raise InvalidMoveError, 'invalid pawn move' 
            else
              return Move::Factory.build(piece, from, to, :enp_capture, enemy)
            end    
          end
        when :K
          if to + [0,2] == from || to + [0,-2] == from
            if to + [0,-2] == from # castle queen-side
              if from == MoveGen::WK_INIT
                rook_from, rook_to = MoveGen::WRQ_INIT, Location::get_location(2,5)
                rook = pos.own_pieces[rook_from]
              else
                rook_from, rook_to = MoveGen::BRQ_INIT, Location::get_location(9,5)
                rook = pos.own_pieces[rook_from]
              end
            else # castle king-side
              if from == MoveGen::WK_INIT
                rook_from, rook_to = MoveGen::WRK_INIT, Location::get_location(2,7)
                rook = pos.own_pieces[rook_from]
              else
                rook_from, rook_to = MoveGen::BRK_INIT, Location::get_location(9,7)
                rook = pos.own_pieces[rook_from]
              end
            end
            raise InvalidMoveError, 'invalid castle move' if rook.nil?
            return Move::Factory.build(piece, from, to, :castle, rook, rook_from, rook_to) 
          else
            return Move::Factory.build(piece, from, to, :king_move)
          end
        else
          return Move::Factory.build(piece, from, to, :regular_move)
        end
      end
    end

  end

end



















