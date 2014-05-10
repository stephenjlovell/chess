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

require './lib/memory.rb'
require './lib/killer.rb'
require './lib/history.rb'

module Chess

  # global variables:
  $INF = 1.0/0.0  # infinity
  $tt = Memory::TranspositionTable.new  # single global transposition table instance.
  $killer = Killer::KillerTable.new     # single global killer table instance.
  $history = History::HistoryTable.new  # single global history table instance.

  # application-level constants:
  FLIP_COLOR = { w: :b, b: :w }
  TIME_LIMIT = 30  # default search time limit
  COLORS = [:w, :b]

  def self.max(x,y)
    x > y ? x : y
  end

  def self.min(x,y)
    x < y ? x : y
  end
  
  def self.colorize(str, color_code)
    "\e[#{color_code}m#{str}\e[0m"
  end

  def self.print_bitboard(b)
    str = "0"*(64-b.to_s(2).length) + b.to_s(2)
    puts "   0 1 2 3 4 5 6 7"
    puts " -----------------"
    i=7
    str.reverse.split(//).each_slice(8).reverse_each do |row| 
      puts "#{i}| #{row.join(" ").gsub("1", Chess::colorize("1",32))}" 
      i-=1
    end
    puts "\n"
  end

  module Notation # supports translation to and from algebraic notation, EPD, and FEN.

    class InvalidMoveError < StandardError
    end

    class NotationFormatError < StandardError
    end

    def self.move_to_str(move)
      move.to_s
    end

    # Create a move object from long algebraic chess notation (used by UCI). Examples:  e2e4, e7e5, e1g1 
    # (white short castling), e7e8q (for promotion).
    def self.str_to_move(pos, str)   
      from = str_to_sq(str[0..1])
      to = str_to_sq(str[2..3])
      move = test_legality(pos, from, to)
    end

    def self.str_to_sq(str)
      raise InvalidMoveError, 'invalid square coordinates given' unless Location::SQUARES[str.to_sym]
      Location::SQUARES[str.to_sym]
    end

    def self.test_legality(pos, from, to)
      piece = pos.board[from]
      if !pos.pieces.friendly?(from, pos.side_to_move) # The from square should be occupied by a friendly piece.
        raise InvalidMoveError, 'No piece available at that square.'
      elsif pos.pieces.friendly?(to, pos.side_to_move) # The to square should NOT be occupied by a friendly piece.
        raise InvalidMoveError, 'This square is already occupied by one of your pieces.'
      # test for king move legality
      elsif !pos.pieces.test_castle_legality(from, to, pos.side_to_move, pos.castle)
        raise InvalidMoveError, 'Invalid castle move'
      # The to square should match the piece movement mask for the given piece type (except in the case of castles).
      elsif !pos.pieces.test_piece_legality(from, to, pos.side_to_move, pos.enp_target)
        raise InvalidMoveError, "The selected piece can\'t move there"
      else
        move = Move::Factory.build_move(pos, from, to)
        unless pos.evades_check?(move)  # The move should not leave the king in check.
          raise InvalidMoveError, 'That move would leave your king in check.'
        end
      end
      return move
    end

    SYM_TO_FEN = { wP: 'P', wN: 'N', wB: 'B', wR: 'R', wQ: 'Q', wK: 'K',
                   bP: 'p', bN: 'n', bB: 'b', bR: 'r', bQ: 'q', bK: 'k' }

    FEN_TO_SYM = SYM_TO_FEN.invert

    def self.position_to_fen(position)
      # opening position example: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1'
      fen_board = piece_placement(position.board)
      fen_side = position.side_to_move.to_s
      fen_castle = castling_availability(position.castle)
      fen_enp = position.enp_target ? position.enp_target.to_s : '-'
      fen_half = position.halfmove_clock.to_s  
      fen_full = ((position.halfmove_clock/2)+1).to_s  # fullmove number
      [fen_board, fen_side, fen_castle, fen_enp, fen_half, fen_full].join(' ')
    end

    def self.piece_placement(board)  # converts board object to a piece placement string in FEN notation.
      id_to_sym = Pieces::PIECE_ID.invert
      board.each_slice(8).to_a.map do |row|
        fen_row, space_counter = '', 0
        row.each do |id|
          if id == 0
            space_counter += 1  # square is empty
          else
            fen_row += space_counter.to_s if space_counter > 0
            fen_row += SYM_TO_FEN[id_to_sym[id]]
            space_counter = 0
          end
        end
        fen_row += space_counter.to_s if space_counter > 0
        fen_row
      end.reject{ |r| r.empty? }.reverse.join('/')
    end

    def self.castling_availability(castle)
      fen_castle = ''
      if castle == 0
        fen_castle = '-'
      else
        fen_castle += 'K' if (castle & MoveGen::C_WK) != 0
        fen_castle += 'Q' if (castle & MoveGen::C_WQ) != 0
        fen_castle += 'k' if (castle & MoveGen::C_BK) != 0
        fen_castle += 'q' if (castle & MoveGen::C_BQ) != 0
      end
      fen_castle
    end

    def self.epd_to_position(epd)
      begin
        fen = epd_to_fen(epd)
        fen_to_position(fen)
      rescue NotationFormatError => e
        raise e
      end
    end

    def self.epd_to_fen(epd)
      epd.split(' ')[0..3].join(' ') + ' 0 1'
    end

    def self.fen_to_position(fen) # Parses a FEN string and returns an equivalent position object.
      # begin
        fields = fen.split(' ') # break the FEN string into its constituent fields
        board = fen_to_board(fields[0])
        side_to_move = fields[1].to_sym
        castle = fen_to_castle(fields[2])
        enp_target = fen_to_enp(fields[3])
        halfmove_clock = fields[4] ? fields[4].to_i : 0
        position = Position.new(board, side_to_move, castle, enp_target, halfmove_clock)
        return position
      # rescue
      #   raise NotationFormatError, "could not convert fen to position: #{fen}"
      # end
    end
    
    def self.fen_to_board(fen)
      id_to_sym = Pieces::PIECE_ID.invert
      board = Chess::Board.new.clear
      fen_rows = fen.split('/').reverse
      sq = 0
      fen_rows.each do |fen_row|
        fen_row.each_char do |char|
          if char =~ /\d/
            sq += char.to_i
          else
            board[sq] = Pieces::PIECE_ID[FEN_TO_SYM[char]]
            sq+=1
          end
        end
      end
      return board
    end

    def self.fen_to_castle(fen_castle)
      castle = 0
      unless fen_castle == '-'
        castle |= MoveGen::C_WK if fen_castle =~ /K/
        castle |= MoveGen::C_WQ if fen_castle =~ /Q/
        castle |= MoveGen::C_BK if fen_castle =~ /k/
        castle |= MoveGen::C_BQ if fen_castle =~ /q/
      end
      castle
    end

    def self.fen_to_enp(fen_enp)
      return nil if fen_enp == '-'
      Location::string_to_location(fen_enp)
    end

  end

end



















