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

    # Send the piece values to the C extension so that any changes made to PIECE_VALUES will be reflected in 
    # the extension.
    # load_piece_values(PIECE_VALUES.values)

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


  end
end

