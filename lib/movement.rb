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
  module Movement

    COLUMNS = { 2 => "a", 3 => "b", 4 => "c", 5 => "d", 
                6 => "e", 7 => "f", 8 => "g", 9 => "h" }
    class Move
      attr_reader :position, :square, :target, 
                  :capture_value, :en_passant, :options

      def initialize(position, square, target, capture_value, options = {})
        @position = position
        @square = square
        @target = target
        @capture_value = capture_value
        @options = options
      end

      def to_s
        piece = @position.pieces[@position.side_to_move][@square]
        "#{piece.symbol.to_s} #{@square} to #{Movement::square(@target[0], @target[1])}"
      end
    end

    def self.square(row,column)
      (COLUMNS[column]) + (row - 1).to_s
    end

    def self.castle!
      # handle castling
    end

    # Mixin methods:

    def get_moves # returns a sorted array of all possible moves for the current player.
      moves = []
      @pieces[@side_to_move].each { |square, piece| moves += piece.get_moves(self) }
      moves.sort! { |x,y| y.capture_value <=> x.capture_value }
      return moves
    end

    def create_position(move) # returns a new position object representing the game 
      # state that results from the current player taking the specified move.
      en_passant_target = nil
      new_position = copy
      new_position.move!(move)
      new_position.previous_move = move
      new_position.side_to_move = @side_to_move == :w ? :b : :w
      return new_position
    end

    def move!(move) # updates self by performing the specified move.
      board = self.board
      piece = self.pieces[self.side_to_move][move.square]
      board[move.target[0],move.target[1]] = board[piece.position[0],piece.position[1]]
      board[piece.position[0], piece.position[1]] = nil

      new_square = Movement::square(move.target[0],move.target[1])
      self.pieces[self.side_to_move][new_square] = piece
      self.pieces[self.side_to_move].delete(move.square)

      if move.options[:en_passant_capture]
        board[piece.position[0], move.target[1]] = nil
        self.pieces[side_to_move].delete(Movement::square(piece.position[0], move.target[1]))
        self.en_passant_target = nil
      elsif move.options[:en_passant_target]
        self.en_passant_target = [move.target[0], move.target[1]]
      end
      piece.position = [move.target[0],move.target[1]]
    end

  end
end



