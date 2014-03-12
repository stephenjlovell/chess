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

module Chess

  # global variables:
  $INF = 1.0/0.0  # infinity
  $tt = Memory::TranspositionTable.new  # single global transposition table instance.

  # application-level constants:
  ENEMY_BACK_ROW = { w: 9, b: 2 }
  FLIP_COLOR = { w: :b, b: :w }
  TIME_LIMIT = 12  # default search time limit

  def self.max(x,y)
    x > y ? x : y
  end

  def self.min(x,y)
    x < y ? x : y
  end
  
  module Notation # supports translation to and from algebraic notation, EPD, and FEN.

    class InvalidMoveError < StandardError
    end

    class NotationFormatError < StandardError
    end

    def self.move_to_str(move)
      move.to_s
    end

    # refactor and break up this method into more manageable pieces:

    def self.str_to_move(pos, str) # create a move object from long algebraic chess notation (used by UCI).
                                   # Examples:  e2e4, e7e5, e1g1 (white short castling), e7e8q (promotion)
      begin
        from = Location::string_to_location(str[0..1])
        to = Location::string_to_location(str[2..3])
        raise if from.nil? || to.nil?
      rescue
        raise InvalidMoveError, 'invalid square coordinates given' 
      end

      raise InvalidMoveError, 'This square is already occupied by one of your pieces.' if pos.own_pieces[to]

      piece, enemy = pos.own_pieces[from], pos.enemy_pieces[to]
      raise InvalidMoveError, "no piece available at square #{from}" if piece.nil?

      own_type = piece.class.type
      if enemy # move is a capture, but not an en-passant capture.
        if own_type == :K
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
          if from + [0,2] == to || from + [0,-2] == to
            # add checks for castling rights here.
            if from + [0,-2] == to # castle queen-side
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


    SYM_TO_FEN = { wP: 'P', wN: 'N', wB: 'B', wR: 'R', wQ: 'Q', wK: 'K',
                   bP: 'p', bN: 'n', bB: 'b', bR: 'r', bQ: 'q', bK: 'k' }

    FEN_TO_SYM = { 'P'=>:wP, 'N'=>:wN, 'B'=>:wB, 'R'=>:wR, 'Q'=>:wQ, 'K'=>:wK,
                   'p'=>:bP, 'n'=>:bN, 'b'=>:bB, 'r'=>:bR, 'q'=>:bQ, 'k'=>:bK }

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
      board.squares.collect do |row|
        fen_row, space_counter = '', 0
        row.each do |sym|
          if SYM_TO_FEN[sym]
            fen_row += space_counter.to_s if space_counter > 0
            fen_row += SYM_TO_FEN[sym]
            space_counter = 0
          elsif sym.nil?
            space_counter += 1  # square is empty
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
        fen = epd.split(' ')[0..3].join(' ')
        fen_to_position(fen)
      rescue NotationFormatError => e
        raise e
      end
    end


    def self.fen_to_position(fen) # Parses a FEN string and returns an equivalent position object.
      begin
        fields = fen.split(' ') # break the FEN string into its constituent fields
        board = fen_to_board(fields[0])
        side_to_move = fields[1].to_sym
        castle = fen_to_castle(fields[2])
        enp_target = fen_to_enp(fields[3])
        halfmove_clock = fields[4] ? fields[4].to_i : 0
        position = Position::ChessPosition.new(board, side_to_move, halfmove_clock)
        position.castle, position.enp_target = castle, enp_target
        position.hash ^= Memory::enp_key(enp_target)
        return position
      rescue
        raise NotationFormatError, "could not convert fen to position: #{fen}"
      end
    end

    IS_NUMERIC = /\d/
    
    def self.fen_to_board(fen)
      board = Chess::Board.new.clear
      squares = board.squares
      fen_rows = fen.split('/').reverse

      board_row = 2
      fen_rows.each do |fen_row|
        board_col = 2
        fen_row.each_char do |c|
          if c =~ IS_NUMERIC
            board_col += c.to_i
          else
            squares[board_row][board_col] = FEN_TO_SYM[c]
            board_col +=1
          end
        end
        board_row += 1
      end
      return board
    end

    def self.fen_to_castle(fen_castle)
      castle = 0
      unless fen_castle[0] == '-'
        castle |= MoveGen::C_WK if fen_castle[0] == 'K'
        castle |= MoveGen::C_WQ if fen_castle[1] == 'Q'
        castle |= MoveGen::C_BK if fen_castle[2] == 'k'
        castle |= MoveGen::C_BQ if fen_castle[3] == 'q'
      end
      castle
    end

    def self.fen_to_enp(fen_enp)
      return nil if fen_enp == '-'
      Location::string_to_location(fen_enp)
    end

  end

end



















