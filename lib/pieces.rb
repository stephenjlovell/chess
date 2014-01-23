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

    PIECE_VALUES = { P: 100, N: 320, B: 333, 
                     R: 510, Q: 880, K: 100000 }

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

      # def copy # return a deep copy of self
      #   self.class.new(@color)
      # end

      def to_s
        @symbol.to_s
      end

      def get_moves(from, position) # returns a collection of all pseudo-legal moves for the current piece.
        moves = []                  # each move contains the piece, to, capture value, and en_passant flag.
        until_blocked = self.class.move_until_blocked?
        self.class.directions.each do |direction|
          move = explore_direction(from, from, direction, position, until_blocked)
          moves += move
        end
        return moves
      end

      private 
      def explore_direction(from, current_location, direction, position, until_blocked, moves = [] )
        to = current_location + direction
        board = position.board
        if board.pseudo_legal?(to, @color)
          if board.avoids_check?(from, to, @color)
            strategy = board.enemy?(to, @color) ? Movement::RegularCapture.new : Movement::RegularMove.new
            moves << Movement::Move.new(self, from, to, strategy)
          end
          if until_blocked && board.empty?(to)
            explore_direction(from, to, direction, position, until_blocked, moves) 
          end
        end
        return moves
      end
    end

    class Pawn < Piece

      class << self
        VALUE = PIECE_VALUES[:P]
        def value
          VALUE
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
        get_en_passant(from, position, position.board, moves) if position.options[:en_passant_target]
        get_advances(from, position, position.board, moves)
        return moves
      end

      def get_attacks(from, position, board, moves)
        self.class.directions[@color][:attack].each do |pair|  # normal attacks
          to = from + pair
          if board.enemy?(to, @color) && board.avoids_check?(from, to, @color)
            enemy = position.enemy_pieces[to]
            moves << Movement::Move.new(self, from, to, Movement::PawnCapture.new(enemy))
          end
        end
      end

      def get_en_passant(from, position, board, moves)
        self.class.directions[:en_passant].each do |pair|
          target = from + pair
          if position.options[:en_passant_target] == target
            offset = self.class.directions[@color][:enp_offset]
            to = target + offset
            if board.avoids_check?(from, to, @color)
              enemy = position.enemy_pieces[to]
              moves << Movement::Move.new(self, from, to, Movement::EnPassantCapture.new(enemy, target))
            end 
          end
        end
      end

      def get_advances(from, position, board, moves)
        dir = self.class.directions[@color]
        to = from + dir[:advance]
        if board.empty?(to)
          if board.avoids_check?(from, to, @color)
            moves << Movement::Move.new(self, from, to, Movement::PawnMove.new)
          end
          if from.r == dir[:start_row]
            to = from + dir[:initial]
            if board.empty?(to)
              if board.avoids_check?(from, to, @color)
                moves << Movement::Move.new(self, from, to, Movement::EnPassantAdvance.new)
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
    end

    def self.get_value_by_sym(sym)
      return 0.0 if sym == nil || sym == :XX
      PIECE_VALUES[sym[1].to_sym]
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

