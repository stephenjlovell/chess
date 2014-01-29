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
  module Pieces

    PIECE_VALUES = { P: 100, N: 320, B: 333, R: 510, Q: 880, K: 100000 }

    PIECE_SYM_VALUES = { wP: 100, wN: 320, wB: 333, wR: 510, wQ: 880, wK: 100000,
                         bP: 100, bN: 320, bB: 333, bR: 510, bQ: 880, bK: 100000, }

    PIECE_ID = { P: 1, N: 2, B: 3, R: 4, Q: 5, K: 6 } # Used for move ordering by MVV-LVA heuristic.

    PIECE_SYM_ID = { wP: 1, wN: 2, wB: 3, wR: 4, wQ: 5, wK: 6,
                     bP: 1, bN: 2, bB: 3, bR: 4, bQ: 5, bK: 6 }

    DIRECTIONS = { straight: [[1,0],[-1,0],[0,1],[0,-1]], 
                   diagonal: [[1,1],[1,-1],[-1,1],[-1,-1]], 
                   N: [[2,1], [1,2], [-2,1], [-1,2], [-2,-1], [-1,-2], [2,-1], [1,-2]], 
                   P: { w: { attack: [[1,1],[1,-1]],
                             advance: [1,0],
                             initial: [2,0],
                             enp_offset: [1,0], 
                             start_row: 3 },
                        b: { attack: [[-1,-1],[-1,1]],
                             advance: [-1,0],                               
                             initial: [-2,0],
                             enp_offset: [-1,0],  
                             start_row: 8 }, 
                        en_passant: [[0,1],[0,-1]]} }

    class Piece  # Provides a common template used by each concrete chess piece class.
      attr_reader :color, :symbol

      def initialize(color)
        @color = color
        @symbol = (@color.to_s + self.class.type.to_s).to_sym
      end

      def to_s
        @symbol.to_s
      end

      def get_moves(from, position) # returns a collection of all pseudo-legal moves for the current piece.
        moves = []                  # each move contains the piece, to, capture value, and en_passant flag.
        self.class.directions.each do |direction|
          more_moves = explore_direction(from, from, direction, position, position.board)
          moves += more_moves
        end
        return moves
      end

      def get_captures(from, position)
        moves = []                  
        self.class.directions.each do |direction|
          more_moves = explore_direction_for_captures(from, from, direction, position, position.board)
          moves += more_moves
        end
        return moves
      end

      private 
      def explore_direction(from, current_location, direction, position, board, moves = [])
        to = current_location + direction
        enemy, empty = board.enemy?(to, @color), board.empty?(to)
        if (empty || enemy) && board.avoids_check?(position, from, to, @color)
          if enemy
            # moves << Move::Move.new(self, from, to, Move::RegularCapture.new(position.enemy_pieces[to]))
            moves << Move::Factory.build(self, from, to, :regular_capture, position.enemy_pieces[to])
          elsif empty
            # moves << Move::Move.new(self, from, to, Move::RegularMove.new)
            moves << Move::Factory.build(self, from, to, :regular_move)
          end
        end
        explore_direction(from, to, direction, position, board, moves) if empty
        return moves
      end

      def explore_direction_for_captures(from, current_location, direction, position, board, moves = [])
        to = current_location + direction
        enemy, empty = board.enemy?(to, @color), board.empty?(to)
        if enemy && board.avoids_check?(position, from, to, @color) 
          # moves << Move::Move.new(self, from, to, 
          #                             Move::RegularCapture.new(position.enemy_pieces[to]))
          moves << Move::Factory.build(self, from, to, :regular_capture, position.enemy_pieces[to])
        end
        explore_direction_for_captures(from, to, direction, position, board, moves) if empty
        return moves
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

      def get_moves(from, position) # supercedes the generic get_moves function 
        moves = []                  # provided by the Piece class.
        get_attacks(from, position, position.board, moves)
        get_en_passant(from, position, position.board, moves) if position.enp_target
        get_advances(from, position, position.board, moves)
        return moves
      end

      def get_captures(from, position)
        moves = []                  
        get_attacks(from, position, position.board, moves)
        get_en_passant(from, position, position.board, moves) if position.enp_target
        return moves
      end

      private

      def get_attacks(from, position, board, moves)
        self.class.directions[@color][:attack].each do |pair|  # normal attacks
          to = from + pair
          if board.enemy?(to, @color) && board.avoids_check?(position, from, to, @color)
            enemy = position.enemy_pieces[to]
            if to.r == ENEMY_BACK_ROW[@color] # determine if pawn promotion
              # Move::PawnPromotionCapture.new(enemy, @color)
              moves << Move::Factory.build(self, from, to, :pawn_promotion_capture, enemy, @color)
            else
              # Move::RegularCapture.new(enemy)
              moves << Move::Factory.build(self, from, to, :regular_capture, enemy)
            end
            # moves << Move::Move.new(self, from, to, strategy)
          end
        end
      end

      def get_en_passant(from, position, board, moves)
        self.class.directions[:en_passant].each do |pair|
          target = from + pair
          if position.enp_target == target
            offset = self.class.directions[@color][:enp_offset]
            to = target + offset
            if board.avoids_check?(position, from, to, @color)
              enemy = position.enemy_pieces[target]
              # moves << Move::Move.new(self, from, to, Move::EnPassantCapture.new(enemy, target))
              moves << Move::Factory.build(self, from, to, :enp_capture, enemy, target)
            end 
          end
        end
      end

      def get_advances(from, position, board, moves)
        dir = self.class.directions[@color]
        to = from + dir[:advance]
        if board.empty?(to)
          if board.avoids_check?(position, from, to, @color)
            if to.r == ENEMY_BACK_ROW[@color] # determine if pawn promotion
              # Move::PawnPromotion.new(@color)
              moves << Move::Factory.build(self, from, to, :pawn_promotion, @color)
            else
              # Move::RegularMove.new
              moves << Move::Factory.build(self, from, to, :regular_move)
            end
            # moves << Move::Move.new(self, from, to, strategy)
          end
          if from.r == dir[:start_row]
            to = from + dir[:initial]
            if board.empty?(to)
              if board.avoids_check?(position, from, to, @color)
                # moves << Move::Move.new(self, from, to, Move::EnPassantAdvance.new)
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

      def get_moves(from, position) # returns a collection of all pseudo-legal moves for the current piece.
        moves = []                  # each move contains the piece, to, capture value, and en_passant flag.
        board = position.board
        self.class.directions.each do |direction|
          to = from + direction
          is_enemy, empty = board.enemy?(to, @color), board.empty?(to)
          if (is_enemy || empty) && board.avoids_check?(position, from, to, @color)
            if is_enemy
              # moves << Move::Move.new(self, from, to, Move::RegularCapture.new(position.enemy_pieces[to]))
              moves << Move::Factory.build(self, from, to, :regular_capture, position.enemy_pieces[to])
            elsif empty
              # moves << Move::Move.new(self, from, to, Move::RegularMove.new)
                moves << Move::Factory.build(self, from, to, :regular_move)
            end
          end
        end
        return moves
      end

      def get_captures(from, position) # returns a collection of all pseudo-legal moves for the current piece.
        moves = []                     # each move contains the piece, to, capture value, and en_passant flag.
        board = position.board
        self.class.directions.each do |direction|
          to = from + direction
          if board.enemy?(to, @color) && board.avoids_check?(position, from, to, @color)
            # moves << Move::Move.new(self, from, to, Move::RegularCapture.new(position.enemy_pieces[to]))
            moves << Move::Factory.build(self, from, to, :regular_capture, position.enemy_pieces[to])
          end
        end
        return moves
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

      def get_moves(from, position) # returns a collection of all pseudo-legal moves for the current piece.
        moves = []                  # each move contains the piece, to, capture value, and en_passant flag.
        board = position.board
        self.class.directions.each do |direction|
          to = from + direction
          is_enemy, empty = board.enemy?(to, @color), board.empty?(to)
          if (is_enemy || empty) && board.avoids_check?(position, from, to, @color, to)
            if is_enemy
              # Move::KingCapture.new(position.enemy_pieces[to])
              moves << Move::Factory.build(self, from, to, :king_capture, position.enemy_pieces[to])
            else
              # Move::KingMove.new
              moves << Move::Factory.build(self, from, to, :king_move)
            end
            # moves << Move::Move.new(self, from, to, strategy)
          end
        end
        return moves
      end

      def get_captures(from, position) # returns a collection of all pseudo-legal moves for the current piece.
        moves = []                  # each move contains the piece, to, capture value, and en_passant flag.
        board = position.board
        self.class.directions.each do |direction|
          to = from + direction
          if board.enemy?(to, @color) && board.avoids_check?(position, from, to, @color, to)
            # moves << Move::Move.new(self, from, to, Move::KingCapture.new(position.enemy_pieces[to]))
            moves << Move::Factory.build(self, from, to, :king_capture, position.enemy_pieces[to])
          end
        end
        return moves
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

