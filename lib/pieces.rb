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

module Application
  module Pieces

    PIECE_VALUES = { P: 100, N: 320, B: 333, R: 510, Q: 880, K: 100000 }

    PIECE_SYM_VALUES = { wP: 100, wN: 320, wB: 333, wR: 510, wQ: 880, wK: 100000,
                         bP: 100, bN: 320, bB: 333, bR: 510, bQ: 880, bK: 100000, }

    PIECE_COLOR = { wP: :w, wN: :w, wB: :w, wR: :w, wQ: :w, wK: :w,
                    bP: :b, bN: :b, bB: :b, bR: :b, bQ: :b, bK: :b }

    PIECES_BY_COLOR = { w: { P: :wP, N: :wN, B: :wB, R: :wR, Q: :wQ, K: :wK }, 
                        b: { P: :bP, N: :bN, B: :bB, R: :bR, Q: :bQ, K: :bK } }

    PIECE_ID = { P: 1, N: 2, B: 3, R: 4, Q: 5, K: 6 } # Used for move ordering by MVV-LVA heuristic.

    PIECE_SYM_ID = { wP: 1, wN: 2, wB: 3, wR: 4, wQ: 5, wK: 6,
                     bP: 1, bN: 2, bB: 3, bR: 4, bQ: 5, bK: 6 }


    # Increment vectors used for move generation:

    NORTH = [1,0]
    NE = [1,1]
    EAST = [0,1]
    SE = [-1,1]
    SOUTH = [-1,0]
    SW = [-1,-1]
    WEST = [0,-1]
    NW = [1,-1]

    NORTH_NW = [2,-1]
    NORTH_NE = [2,1]
    EAST_NE = [1,2]
    EAST_SE = [-1,2]
    SOUTH_SE = [-2,1]
    SOUTH_SW = [-2,-1]
    WEST_SW = [-1,-2]
    WEST_NW = [1,-2]

    # order the directions so that directions "facing the enemy" are tried first by default.

    # ordering for white:

    # { w: { straight: [NORTH, EAST, WEST, SOUTH],
    #        diagonal: [NE, NW, SE, SW],
    #        ray: [NORTH, NE, NW, EAST, WEST, SE, SW, SOUTH] },
    #   b: { straight: [SOUTH, WEST, EAST, NORTH],
    #        diagonal: [SE, SW, NE, NW],
    #        ray: [SOUTH, SE, SW, WEST, EAST, NW, NE, NORTH] } }

    DIRECTIONS = { straight: [NORTH, SOUTH, EAST, WEST], 
                   diagonal: [NE, NW, SE, SW],
                   ray: [NORTH, NE, EAST, SE, SOUTH, SW, WEST, NW], 
                   N: [NORTH_NW, NORTH_NE, EAST_NE, EAST_SE, SOUTH_SE, SOUTH_SW, WEST_SW, WEST_NW], 
                   P: { w: { attack: [NE, NW],
                             advance: NORTH,
                             initial: [2,0],
                             enp_offset: NORTH, 
                             start_row: 3 },
                        b: { attack: [SE, SW],
                             advance: SOUTH,                               
                             initial: [-2,0],
                             enp_offset: SOUTH,  
                             start_row: 8 }, 
                        en_passant: [EAST, WEST]} }

    class Piece  # Provides a common template used by each concrete chess piece class.
      attr_reader :color, :symbol

      def initialize(color)
        @color = color
        @symbol = (@color.to_s + self.class.type.to_s).to_sym
      end

      def to_s
        @symbol.to_s
      end

      def get_moves(position, from, moves, captures, promotions, promotion_captures) # returns a collection of all pseudo-legal moves for the current piece.
        self.class.directions.each { |vector| get_moves_for_direction(position, position.board, from, vector, moves, captures) }
      end

      def get_captures(position, from, captures, promotion_captures) # returns a collection of all pseudo-legal moves for the current piece.
        self.class.directions.each { |vector| get_captures_for_direction(position, position.board, from, vector, captures) }
      end

      private 

      def get_moves_for_direction(position, board, from, vector, moves, captures)
        to = from + vector
        while board.on_board?(to)
          if (board.empty?(to) || board.enemy?(to, @color)) 
            if board.avoids_check?(position, from, to, @color)
              if board.empty?(to)
                moves << Move::Factory.build(self, from, to, :regular_move)
              else
                captures << Move::Factory.build(self, from, to, :regular_capture, position.enemy_pieces[to])
                break
              end
            end
          else
            break # if path blocked by friendly piece, stop evaluating this direction.
          end
          to += vector
        end
      end

      def get_captures_for_direction(position, board, from, vector, captures)
        to = from + vector
        while board.on_board?(to)
          if (board.empty?(to) || board.enemy?(to, @color)) 
            if board.enemy?(to, @color) && board.avoids_check?(position, from, to, @color)
              captures << Move::Factory.build(self, from, to, :regular_capture, position.enemy_pieces[to])
            end
            break
          else
            break # if path blocked by friendly piece, stop evaluating this direction.
          end
          to += vector
        end
      end

    end

    class Pawn < Piece
      class << self
        VALUE = PIECE_VALUES[:P]
        def value
          VALUE
        end

        ID = PIECE_ID[:P]
        def id
          ID
        end

        def type
          :P
        end

        def move_until_blocked?
          false
        end

        PAWN_DIRECTIONS = DIRECTIONS[:P]
        def directions
          PAWN_DIRECTIONS
        end
      end

      def get_moves(position, from, moves, captures, promotions, promotion_captures) 
        get_attacks(position, position.board, from, captures, promotion_captures)
        get_en_passant(position, position.board, from, captures) if position.enp_target
        get_advances(position, position.board, from, moves, promotions)
      end

      def get_captures(position, from, captures, promotion_captures)         
        get_attacks(position, position.board, from, captures, promotion_captures)
        get_en_passant(position, position.board, from, captures) if position.enp_target
      end

      private

      def get_attacks(position, board, from, captures, promotion_captures)
        self.class.directions[@color][:attack].each do |vector|  # normal attacks
          to = from + vector
          if board.enemy?(to, @color) && board.avoids_check?(position, from, to, @color)
            enemy = position.enemy_pieces[to]
            if to.r == ENEMY_BACK_ROW[@color] # determine if pawn promotion
              promotion_captures << Move::Factory.build(self, from, to, :pawn_promotion_capture, enemy, @color)
            else
              captures << Move::Factory.build(self, from, to, :regular_capture, enemy)
            end
          end
        end
      end

      def get_en_passant(position, board, from, captures)
        self.class.directions[:en_passant].each do |pair|
          target = from + pair
          if position.enp_target == target
            offset = self.class.directions[@color][:enp_offset]
            to = target + offset
            if board.avoids_check?(position, from, to, @color)
              enemy = position.enemy_pieces[target]
              captures << Move::Factory.build(self, from, to, :enp_capture, enemy, target)
            end 
          end
        end
      end

      def get_advances(position, board, from, moves, promotions)
        dir = self.class.directions[@color]
        to = from + dir[:advance]
        if board.empty?(to)
          if board.avoids_check?(position, from, to, @color)
            if to.r == ENEMY_BACK_ROW[@color] # determine if pawn promotion
              promotions << Move::Factory.build(self, from, to, :pawn_promotion, @color)
            else
              moves << Move::Factory.build(self, from, to, :regular_move)
            end
          end
          if from.r == dir[:start_row]
            to = from + dir[:initial]
            if board.empty?(to)
              if board.avoids_check?(position, from, to, @color)
                moves << Move::Factory.build(self, from, to, :enp_advance)
              end
            end
          end
        end
      end

    end

    class Knight < Piece
      class << self
        VALUE = PIECE_VALUES[:N]
        def value
          VALUE
        end

        ID = PIECE_ID[:N]
        def id
          ID
        end

        def type
          :N
        end

        def move_until_blocked?
          false
        end

        KNIGHT_DIRECTIONS = DIRECTIONS[:N]
        def directions
          KNIGHT_DIRECTIONS
        end
      end

      def get_moves(position, from, moves, captures, promotions, promotion_captures)              
        board = position.board
        self.class.directions.each do |vector|
          to = from + vector
          if (board.empty?(to) || board.enemy?(to, @color)) && board.avoids_check?(position, from, to, @color)
            if board.empty?(to)
              moves << Move::Factory.build(self, from, to, :regular_move)
            else
              captures << Move::Factory.build(self, from, to, :regular_capture, position.enemy_pieces[to])
            end
          end
        end
      end

      def get_captures(position, from, captures, promotion_captures) # returns a collection of all pseudo-legal moves for the current piece.
        board = position.board
        self.class.directions.each do |vector|
          to = from + vector
          if board.enemy?(to, @color) && board.avoids_check?(position, from, to, @color)
            captures << Move::Factory.build(self, from, to, :regular_capture, position.enemy_pieces[to])
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

        ID = PIECE_ID[:B]
        def id
          ID
        end

        def type
          :B
        end

        def move_until_blocked?
          true
        end

        BISHOP_DIRECTIONS = DIRECTIONS[:diagonal]
        def directions
          BISHOP_DIRECTIONS
        end
      end
    end

    class Rook < Piece
      class << self
        VALUE = PIECE_VALUES[:R]
        def value
          VALUE
        end

        ID = PIECE_ID[:R]
        def id
          ID
        end

        def type
          :R
        end

        def move_until_blocked?
          true
        end

        ROOK_DIRECTIONS = DIRECTIONS[:straight]
        def directions
          ROOK_DIRECTIONS
        end
      end
    end

    class Queen < Piece
      class << self
        VALUE = PIECE_VALUES[:Q]
        def value
          VALUE
        end

        ID = PIECE_ID[:Q]
        def id
          ID
        end

        def type
          :Q
        end

        def move_until_blocked?
          true
        end

        QUEEN_DIRECTIONS = DIRECTIONS[:diagonal] + DIRECTIONS[:straight]
        def directions
          QUEEN_DIRECTIONS
        end
      end
    end

    class King < Piece
      class << self
        VALUE = PIECE_VALUES[:K]
        def value
          VALUE
        end

        ID = PIECE_ID[:K]
        def id
          ID
        end

        def type
          :K
        end

        def move_until_blocked?
          false
        end

        KING_DIRECTIONS = DIRECTIONS[:diagonal] + DIRECTIONS[:straight]
        def directions
          KING_DIRECTIONS
        end
      end

      def get_moves(position, from, moves, captures, promotions, promotion_captures)   
        board = position.board
        self.class.directions.each do |vector|
          to = from + vector
          if (board.empty?(to) || board.enemy?(to, @color)) && board.avoids_check?(position, from, to, @color, to)
            if board.empty?(to)
              moves << Move::Factory.build(self, from, to, :king_move)
            else
              captures << Move::Factory.build(self, from, to, :king_capture, position.enemy_pieces[to])
            end
          end
        end
      end

      def get_captures(position, from, captures, promotion_captures) 
        board = position.board
        self.class.directions.each do |direction|
          to = from + direction
          if board.enemy?(to, @color) && board.avoids_check?(position, from, to, @color, to)
            captures << Move::Factory.build(self, from, to, :king_capture, position.enemy_pieces[to])
          end
        end
      end

    end

    def self.get_value_by_sym(sym)
      return 0 if sym == nil || sym == :XX
      PIECE_SYM_VALUES[sym]
    end

    def self.setup(board)        # returns a collection of chess pieces 
      pieces = { w: {}, b: {} }  # corresponding to the specified board representation.
      board.each_square_with_location do |r,c,sym|
        unless sym.nil?
          piece = self.create_piece_by_sym(sym)
          pieces[piece.color][Location::get_location(r,c)] = piece
        end
      end
      return pieces
    end

    def self.create_piece_by_sym(sym)
      color, type = sym[0].to_sym, sym[1]
      case type
      when "P" then Pawn.new(color)
      when "R" then Rook.new(color)
      when "N" then Knight.new(color)
      when "B" then Bishop.new(color)
      when "Q" then Queen.new(color)
      when "K" then King.new(color)
      end
    end

  end
end

