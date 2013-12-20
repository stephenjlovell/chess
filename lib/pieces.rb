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

      def initialize(color)
        @color = color
      end

      def copy # return a deep copy of self
        self.class.new(@color)
      end

      def symbol
        @symbol ||= (@color.to_s + self.class.type.to_s).to_sym
      end

      def get_moves(from, position) # returns a collection of all pseudo-legal moves for the current piece.
        moves = []                  # each move contains the piece, to, capture value, and en_passant flag.
        until_blocked = self.class.move_until_blocked?
        self.class.directions.each do |direction|
          move = explore_direction(from, direction, position, until_blocked)
          moves += move unless move.empty?
        end
        return moves
      end

      private 
        def explore_direction(from, direction, position, until_blocked, moves = [] )
          to = from + direction
          board = position.board
          if board.pseudo_legal?(to, @color)
            moves << Movement::Move.new(position, from, to, mvv_lva_value(to, board))
            if until_blocked && board.empty?(to)
              explore_direction(to, direction, position, until_blocked, moves) 
            end
          end
          return moves
        end

        def mvv_lva_value(to, board)
          board.enemy?(to, @color) ? (Pieces::get_value_by_sym(board[to])/self.class.value) : 0.0
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

      def get_moves(from, position) # supercedes the generic get_moves function 
        moves = []                  # provided by the Piece class.
        get_attacks(from, position, moves)
        get_en_passant(from, position, moves)
        get_advances(from, position, moves)
        return moves
      end

      def get_attacks(from, position, moves)
        board = position.board        
        DIRECTIONS[@color][:attack].each do |pair|  # normal attacks
          to = from + pair
          if board.enemy?(to, @color)  
            moves << Movement::Move.new(position, from, to, mvv_lva_value(to, board))
          end
        end
      end

      def get_en_passant(from, position, moves)
        board = position.board
        DIRECTIONS[:en_passant].each do |pair|
          target = from + pair
          if position.en_passant_target?(target) && board.enemy?(target, @color)
            offset = DIRECTIONS[@color][:enp_offset]
            move_to = target + offset
            moves << Movement::EnPassantAttack.new(position, from, move_to) 
          end
        end
      end

      def get_advances(from, position, moves)
        dir = DIRECTIONS[@color]
        to = from + dir[:advance]
        unless position.board.occupied?(to)
          moves << Movement::Move.new(position, from, to, 0.0)
          if from.r == dir[:start_row]
            to = from + dir[:initial]
            unless position.board.occupied?(to)
              moves << Movement::EnPassantTarget.new(position, from, to) 
            end
          end
        end
      end

      def mvv_lva_value(to, board) # most valuable victim / least valuable attacker heuristic
        (Pieces::get_value_by_sym(board[to])/self.class.value)
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

    def self.setup(board)        # returns a collection of chess pieces 
      pieces = { w: {}, b: {} }  # corresponding to the specified board representation.
      board.each_with_index do |row, r|
        row.each_with_index do |sym, c|
          unless sym == nil || sym == :XX
            piece = self.create_piece_by_sym(sym)
            pieces[piece.color][Movement::Location.new(r, c)] = piece
          end
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

