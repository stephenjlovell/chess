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
  module GUI # This module serves as a wrapper for a Universal Chess Interface (UCI) based GUI.

# Wikipedia:
# A FEN record contains six fields. The separator between fields is a space. The fields are:
# Piece placement (from white's perspective). Each rank is described, starting with rank 8 and ending with rank 1; within each rank, 
# the contents of each square are described from file "a" through file "h". Following the Standard Algebraic Notation (SAN), each piece is identified by a single letter taken from the standard English names (pawn = "P", knight = "N", bishop = "B", rook = "R", queen = "Q" and king = "K").[1] 
# White pieces are designated using upper-case letters ("PNBRQK") while black pieces use lowercase ("pnbrqk"). Empty squares are noted using digits 1 through 8 (the number of empty squares), and "/" separates ranks.
# Active color. "w" means White moves next, "b" means Black.
# Castling availability. If neither side can castle, this is "-". Otherwise, this has one or more letters: "K" (White can castle kingside), "Q" (White can castle queenside), "k" (Black can castle kingside), and/or "q" (Black can castle queenside).
# En passant target square in algebraic notation. If there's no en passant target square, this is "-". If a pawn has just made a two-square move, this is the position "behind" the pawn. This is recorded regardless of whether there is a pawn in position to make an en passant capture.[2]
# Halfmove clock: This is the number of halfmoves since the last capture or pawn advance. This is used to determine if a draw can be claimed under the fifty-move rule.
# Fullmove number: The number of the full move. It starts at 1, and is incremented after Black's move.

    FEN_PIECES = { wP: "P", wN: "N", wB: "B", wR: "R", wQ: "Q", wK: "K",
                   bP: "p", bN: "n", bB: "b", bR: "r", bQ: "q", bK: "k" }


    def self.position_to_fen(position)
      # opening position example: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
      board = position.board
      fen = ""

      fen_board = board.squares.collect do |row|
        fen_row, space_counter = "", 0
        row.each do |sym|
          if FEN_PIECES[sym]
            fen_row += space_counter.to_s if space_counter > 0
            fen_row += FEN_PIECES[sym]
            space_counter = 0
          elsif sym.nil?
            space_counter += 1  # square is empty
          end
        end
        fen_row += space_counter.to_s if space_counter > 0
        fen_row
      end.reject{ |r| r.empty? }.reverse.join("/")
      fen_side = position.side_to_move.to_s
      castle, fen_castle = position.castle, ""
      if castle == 0b0000
        fen_castle = "-"
      else
        fen_castle += "K" if castle & MoveGen::C_WK
        fen_castle += "Q" if castle & MoveGen::C_WQ
        fen_castle += "k" if castle & MoveGen::C_BK
        fen_castle += "q" if castle & MoveGen::C_BQ
      end

      fen_enp = position.enp_target ? position.enp_target.to_s : "-"
      fen_half = position.halfmove_clock.to_s
      fen_full = ((position.halfmove_clock/2)+1).to_s

      [fen_board, fen_side, fen_castle, fen_enp, fen_half, fen_full].join(" ")

    end    


    def self.fen_to_position(fen) # instantiate a position object based on the 


    end

  end
end










