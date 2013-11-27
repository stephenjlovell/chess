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

    PIECE_VALUES = { "P" => 100, "N" => 320, "B" => 333, 
                     "R" => 510, "Q" => 880, "K" => 100000 }

    class Piece  # this class defines the common behavior of chess pieces.
      attr_reader :color 
      attr_accessor :position

      def initialize(row, column, color)
        @color = color
        @position = [row, column]
      end

      def copy # return a deep copy of self
        self.class.new(*@position, @color)
      end

      def symbol
        @symbol ||= (@color.to_s + self.class.type.to_s).to_sym
      end

      def square
        @square ||= Movement::square(*@position)
      end

      def get_moves(chess_position) # returns a collection of all pseudo-legal moves for the current piece.
        moves = []                  # each move contains the piece, target, capture value, and en_passant flag.
        self.class.directions.each do |direction|
          move = explore_direction(@position, direction, chess_position)
          moves += move unless move.empty?
        end
        return moves
      end

      private 
        def explore_direction(start, direction, chess_position, moves = [] )
          target = [ start[0] + direction[0], start[1] + direction[1]]
          board = chess_position.board
          if board.pseudo_legal?(*target, @color)
            moves << Movement::Move.new(chess_position, self.square, target, 
                                        mvv_lva_value(target, board))
            if self.class.move_until_blocked? && board.empty?(*target)
              explore_direction(target, direction, chess_position, moves) 
            end
          end
          return moves
        end

        def mvv_lva_value(target, board, enemy = nil)
          if enemy || board.enemy?(*target, @color)
            Pieces::get_value_by_sym(board[*target]) / self.class.value
          else
            0.0
          end
        end
    end

    class Pawn < Piece
      DIRECTIONS = { w: { attack: [[1,1],[1,-1]],
                          advance: [1,0],
                          initial: [2,0],
                          enp_offset: [1,0], 
                          start_row: 3 },
                     b: { attack: [[-1,-1],[-1,1]],
                          advance: [-1,0],                               
                          initial: [-2,0],
                          enp_offset: [-1,0],  
                          start_row: 8 }, 
                     en_passant: [[0,1],[0,-1]] }

      class << self
        VALUE = PIECE_VALUES["P"]
        def value
          VALUE
        end

        def type
          :P
        end

        def move_until_blocked?
          false
        end
      end

      def get_moves(chess_position) # supercedes the generic get_moves function 
        moves = []                  # provided by the Piece class.
        get_attacks(chess_position,moves)
        get_en_passant(chess_position,moves)
        get_advances(chess_position,moves)
        return moves
      end

      def get_attacks(chess_position, moves)
        attacks = DIRECTIONS[@color][:attack]
        attacks.each do |pair|  # normal attacks
          target = [ @position[0] + pair[0], @position[1] + pair[1]]
          board = chess_position.board
          if board.enemy?(*target, @color)  
            moves << Movement::Move.new(chess_position, self.square, target, 
                                        mvv_lva_value(target, chess_position.board, true))
          end
        end
      end

      def get_en_passant(chess_position, moves)
        DIRECTIONS[:en_passant].each do |pair|
          target = [ @position[0] + pair[0], @position[1] + pair[1]]
          b = chess_position.board
          if chess_position.en_passant_target?(target[0],target[1]) && 
          b.enemy?(target[0],target[1], @color)
            offset = DIRECTIONS[@color][:enp_offset]
            move_target = [target[0] + offset[0], target[1] + offset[1]]
            moves << Movement::Move.new(chess_position, self.square, move_target, 
                                        1.0,  { en_passant_capture: true }) 
          end
        end
      end

      def get_advances(chess_position, moves)
        d = DIRECTIONS[@color]
        target = [ @position[0] + d[:advance][0], @position[1] + d[:advance][1] ]
        board = chess_position.board
        unless board.occupied?(target[0], target[1])
          moves << Movement::Move.new(chess_position, self.square, target, 0.0)
          if @position[0] == d[:start_row]
            target = [ @position[0] + d[:initial][0], @position[1] + d[:initial][1]]
            unless board.occupied?(target[0], target[1])
              moves << Movement::Move.new(chess_position, self.square, target, 
                                          0.0, { en_passant_target: true }) 
            end
          end
        end
      end

    end

    class Knight < Piece
      class << self
        VALUE = PIECE_VALUES["N"]
        def value
          VALUE
        end

        def type
          :N
        end

        def move_until_blocked?
          false
        end

        def directions
          [[2,1], [1,2], [-2,1], [-1,2], [-2,-1], [-1,-2], [2,-1], [1,-2]]
        end
      end
    end

    class Bishop < Piece
      class << self
        VALUE = PIECE_VALUES["B"]
        def value
          VALUE
        end

        def type
          :B
        end

        def move_until_blocked?
          true
        end

        def directions
          [[1,1],[1,-1],[-1,1],[-1,-1]]
        end
      end
    end

    class Rook < Piece
      class << self
        VALUE = PIECE_VALUES["R"]
        def value
          VALUE
        end

        def type
          :R
        end

        def move_until_blocked?
          true
        end

        def directions
          [[1,0],[-1,0],[0,1],[0,-1]]
        end
      end
    end

    class Queen < Piece
      class << self
        VALUE = PIECE_VALUES["Q"]
        def value
          VALUE
        end

        def type
          :Q
        end

        def move_until_blocked?
          true
        end

        def directions
          [[1,0],[-1,0],[0,1],[0,-1],[1,1],[1,-1],[-1,1],[-1,-1]]
        end
      end
    end

    class King < Piece
      class << self
        VALUE = PIECE_VALUES["K"]
        def value
          VALUE
        end

        def type
          :K
        end

        def move_until_blocked?
          false
        end

        def directions
          [[1,0],[-1,0],[0,1],[0,-1],[1,1],[1,-1],[-1,1],[-1,-1]]
        end
      end
    end

    def self.get_value_by_sym(sym)
      return 0.0 if sym == nil || sym == :XX
      PIECE_VALUES[sym[1]]
    end

    def self.setup(board)  # returns an array of new chess piece objects corresponding to the 
      pieces = { w: {}, b: {} }         # board representation specified in board.
      board.each_with_index do |row, row_index|
        row.each_with_index do |sym, column|
          unless sym == nil || sym == :XX
            piece = self.create_piece_by_sym(row_index, column, sym) 
            pieces[piece.color][piece.square] = piece
          end
        end
      end
      return pieces
    end

    def self.create_piece_by_sym(row, column, sym)
      color, type = sym[0].to_sym, sym[1]
      case type
      when "P" then Pawn.new(row, column, color)
      when "R" then Rook.new(row, column, color)
      when "N" then Knight.new(row, column, color)
      when "B" then Bishop.new(row, column, color)
      when "Q" then Queen.new(row, column, color)
      when "K" then King.new(row, column, color)
      end
    end

  end
end

