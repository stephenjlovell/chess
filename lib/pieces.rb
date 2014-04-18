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
# CONORTH_NECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#-----------------------------------------------------------------------------------

module Chess
  module Pieces

    # Create an integer representation of each piece.  This allows a piece from the board to be quickly unpacked into
    # its color and type, and allows this information to be passed to the C extension without incurring much overhead.
    # The first (least-significant) bit is always 1 and indicates occupancy of a square.
    # The second bit represents the color (white = 1).  
    # The next 3 bits represent the piece ID.
    PIECE_ID = { wP: 17, wN: 19, wB: 21, wR: 23, wQ: 25, wK: 27,
                 bP: 16, bN: 18, bB: 20, bR: 22, bQ: 24, bK: 26 }

    PIECE_TYPES = [ :P, :N, :B, :R, :Q, :K ] 

    PIECE_SYMBOLS = [ :wP, :wN, :wB, :wR, :wQ, :wK, :bP, :bN, :bB, :bR, :bQ, :bK ]

    # Assign each piece a base material value approximating its relative importance.      
    PIECE_VALUES = { P: 100, N: 320, B: 333, R: 510, Q: 880, K: 100000 }

    # This constant represents the maximum value of all non-king pieces for each side.  ~4,006
    NON_KING_VALUE = PIECE_VALUES[:P]*8 + PIECE_VALUES[:N]*2 + PIECE_VALUES[:B]*2 + 
                     PIECE_VALUES[:R]*2 + PIECE_VALUES[:Q]

    # When a player has lost 2/3 of their pieces by value, they are considered to be in the 'endgame'.  
    # Endgame state is used during Evaluation.
    ENDGAME_VALUE = PIECE_VALUES[:K] + NON_KING_VALUE/4

    # During search, an evaluation score less than KING_LOSS indicates that the king will be captured in the next ply. This
    # is used to avoid illegal moves without the overhead cost of checking each possible move for full legality.
    KING_LOSS = NON_KING_VALUE - PIECE_VALUES[:K] 

    # This constant provides a finite evaluation score indicating checkmate.   
    MATE = NON_KING_VALUE + PIECE_VALUES[:K]

    # This hash associates piece symbols with their underlying color.
    PIECE_COLOR = { wP: :w, wN: :w, wB: :w, wR: :w, wQ: :w, wK: :w,
                    bP: :b, bN: :b, bB: :b, bR: :b, bQ: :b, bK: :b }

    # This hash associates piece symbols with their underlying type.
    PIECE_TYPE = { wP: :P, wN: :N, wB: :B, wR: :R, wQ: :Q, wK: :K,
                   bP: :P, bN: :N, bB: :B, bR: :R, bQ: :Q, bK: :K }

    ENEMY_BACK_ROW = { w: 9, b: 2 }

    CAN_PROMOTE = { w: 8, b: 3 }


    # set up bitmask used to unpack to/from pairs sent from movegen.c
    FROM_MASK = 0b111111


    #  The abstract Piece class provides a shared interface and defualt behavior for its subclasses. Each concrete 
    #  piece instance can:
    #
    #  1. generate all pseudo-legal moves (moves that may or may not leave the king in check, but which are
    #     otherwise legal) available to its type, including captures, for the current position. 
    #  2. generate captures only. This is used during Quiesence Search.

    class Piece  
      attr_reader :color, :symbol

      def initialize(color)
        @color, @symbol = color, (color.to_s + self.class.type.to_s).to_sym
      end

      def to_s
        @symbol.to_s
      end

    end


    #  Pawns behave differently than other pieces. They: 
    #  1. can move only in one direction;
    #  2. can attack diagonally but can only advance on file (forward);
    #  3. can move an extra space from the starting square;
    #  4. can capture other pawns via the En-Passant Rule;
    #  5. are promoted to another piece type if they reach the enemy's back rank.

    class Pawn < Piece

      class << self
        VALUE = PIECE_VALUES[:P]
        def value
          VALUE
        end

        def type
          :P
        end


        def get_non_captures(pos, moves, pieces, occupied)
          
        end

        def get_captures(pos, moves, pieces, occupied, enemy)

        end 
        
        private

        # Add any valid regular pawn attacks to move array. Pawns may only attack toward the enemy side.

        # Add any valid En-Passant captures to move array. Any pawn that made a double move on the previous turn 

        # Add any valid non-capture moves to move array, including promotions and double moves (En-Passant advances).

        # Get only advances resulting in pawn promotion.

      end

    end


    class Knight < Piece
      class << self
        VALUE = PIECE_VALUES[:N]
        def value
          VALUE
        end

        def type
          :N
        end

        def get_non_captures(pos, moves, pieces, occupied)
          knights = pieces[:N]
          get_knight_non_captures(knights, occupied).each do |pair|
            from, to = (pair & FROM_MASK), (pair >> 6)
            moved_piece ||= pos.board[from]
            moves.push(Move::Factory.build(moved_piece, from, to, :regular_move))
          end
        end

        def get_captures(pos, moves, pieces, occupied, enemy)
          knights = pieces[:N]
          moved_piece = nil
          get_knight_captures(knights, enemy).each do |pair|
            from, to = (pair & FROM_MASK), (pair >> 6)
            moved_piece ||= pos.board[from]
            captured_piece = pos.board[to]
            moves.push(Move::Factory.build(moved_piece, from, to, :regular_capture, captured_piece))
          end
        end 

      end
    end

    class Bishop < Piece
      class << self
        VALUE = PIECE_VALUES[:B]
        def value
          VALUE
        end

        def type
          :B
        end

        def get_non_captures(pos, moves, pieces, occupied)
          bishops = pieces[:B]
          get_bishop_non_captures(bishops, occupied).each do |pair|
            from, to = (pair & FROM_MASK), (pair >> 6)
            moved_piece ||= pos.board[from]
            moves.push(Move::Factory.build(moved_piece, from, to, :regular_move))
          end
        end

        def get_captures(pos, moves, pieces, occupied, enemy)
          bishops = pieces[:B]
          get_bishop_captures(bishops, occupied, enemy).each do |pair|
            from, to = (pair & FROM_MASK), (pair >> 6)
            moved_piece ||= pos.board[from]
            captured_piece = pos.board[to]
            moves.push(Move::Factory.build(moved_piece, from, to, :regular_capture, captured_piece))
          end
        end

      end
    end

    class Rook < Piece
      class << self
        VALUE = PIECE_VALUES[:R]
        def value
          VALUE
        end

        def type
          :R
        end

        def get_non_captures(pos, moves, pieces, occupied)
          rooks = pieces[:R]
          get_rook_non_captures(rooks, occupied).each do |pair|
            from, to = (pair & FROM_MASK), (pair >> 6)
            moved_piece ||= pos.board[from]
            moves.push(Move::Factory.build(moved_piece, from, to, :regular_move))
          end
        end

        def get_captures(pos, moves, pieces, occupied, enemy)
          rooks = pieces[:R]
          get_rook_captures(rooks, occupied, enemy).each do |pair|
            from, to = (pair & FROM_MASK), (pair >> 6)
            moved_piece ||= pos.board[from]
            captured_piece = pos.board[to]
            moves.push(Move::Factory.build(moved_piece, from, to, :regular_capture, captured_piece))
          end
        end

      end
    end

    class Queen < Piece
      class << self
        VALUE = PIECE_VALUES[:Q]
        def value
          VALUE
        end

        def type
          :Q
        end

        def get_non_captures(pos, moves, pieces, occupied)
          queens = pieces[:Q]
          get_queen_non_captures(queens, occupied).each do |pair|
            from, to = (pair & FROM_MASK), (pair >> 6)
            moved_piece ||= pos.board[from]
            moves.push(Move::Factory.build(moved_piece, from, to, :regular_move))
          end
        end

        def get_captures(pos, moves, pieces, occupied, enemy)
          queens = pieces[:Q]
          get_queen_captures(queens, occupied, enemy).each do |pair|
            from, to = (pair & FROM_MASK), (pair >> 6)
            moved_piece ||= pos.board[from]
            captured_piece = pos.board[to]
            moves.push(Move::Factory.build(moved_piece, from, to, :regular_capture, captured_piece))
          end
        end

      end
    end

    class King < Piece
      class << self
        VALUE = PIECE_VALUES[:K]
        def value
          VALUE
        end

        def type
          :K
        end

        def get_non_captures(pos, moves, pieces, occupied)
          kings = pieces[:K]
          get_king_non_captures(kings, occupied).each do |pair|
            from, to = (pair & FROM_MASK), (pair >> 6)
            moved_piece ||= pos.board[from]
            moves.push(Move::Factory.build(moved_piece, from, to, :king_move))
          end
        end

        def get_captures(pos, moves, pieces, occupied, enemy)
          kings = pieces[:K]
          moved_piece = nil
          get_king_captures(kings, enemy).each do |pair|
            from, to = (pair & FROM_MASK), (pair >> 6)
            moved_piece ||= pos.board[from]
            captured_piece = pos.board[to]
            moves.push(Move::Factory.build(moved_piece, from, to, :king_capture, captured_piece))
          end
        end

      end
    end

    def self.set_piece_sym_values
      hsh = { wP: PIECE_VALUES[:P], wN: PIECE_VALUES[:N], wB: PIECE_VALUES[:B], 
              wR: PIECE_VALUES[:R], wQ: PIECE_VALUES[:Q], wK: PIECE_VALUES[:K],
              bP: PIECE_VALUES[:P], bN: PIECE_VALUES[:N], bB: PIECE_VALUES[:B], 
              bR: PIECE_VALUES[:R], bQ: PIECE_VALUES[:Q], bK: PIECE_VALUES[:K] }
      hsh.default = 0
      return hsh
    end

    # This hash associates piece symbols with the value of their piece type.
    PIECE_SYM_VALUES = set_piece_sym_values

    def self.get_value_by_sym(sym)
      PIECE_SYM_VALUES[sym]
    end

    def self.send_to_each(method, *args)
      Pawn.send(method, *args)
      Knight.send(method, *args)
      Bishop.send(method, *args)
      Rook.send(method, *args)
      Queen.send(method, *args)
      King.send(method, *args)
    end

  end
end

