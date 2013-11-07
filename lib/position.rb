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
  module Position

    # ChessPosition describes the game state as of a specific turn. Should describe the following:
    # Piece placement, side to move, castling rights, en passant target square
    class ChessPosition
      attr_accessor :board, :pieces,  :side_to_move, :en_passant_target, :previous_move

      def initialize(board, pieces, side_to_move, en_passant_target = nil, previous_move = nil)
        @board = board
        @pieces = pieces   # pieces collection generated via Pieces::Setup
        @side_to_move = side_to_move
        @en_passant_target = en_passant_target
        @previous_move = previous_move
      end

      def en_passant_target?(row, column)
        return false if @en_passant_target.nil?
        @en_passant_target[0] == row && @en_passant_target[1] == column
      end

      def value
        @value ||= Evaluation::evaluate(self)
      end

      def value=(value)
        @value = value
      end

      def to_s
         # return a string decribing the position in Forsyth-Edwards Notation.
      end

      def edges
        get_moves.collect do |move|
          create_position(move)
        end
      end

      # These methods will eventually be located in Application::Movement 
      # and mixed in to the Position class:

      def get_moves # returns a sorted array of all possible moves for the current player.
        moves = []
        @pieces[@side_to_move].each { |coordinates, piece| moves += piece.get_moves(self) }  # refactor 
        moves.sort! { |x,y| y.capture_value <=> x.capture_value }
        return moves
      end

      def create_position(move) # returns a new position object representing the
        # game state that results from the current player at position taking the specified move.
        en_passant_target = nil
        new_position = copy
        new_position.move!(move)
        new_position.previous_move = move
        new_position.side_to_move = @side_to_move == :w ? :b : :w
        return new_position
      end

      def copy
        pieces = { w: {}, b: {} }
        @pieces.each do |color, coordinates_hash|
          @pieces[color].each do |coordinate, piece|
            pieces[color][coordinate] = piece.copy
          end
        end
        en_passant_target = if @en_passant_target.nil?
          nil
        else
          [@en_passant_target[0], @en_passant_target[1]]
        end 
        ChessPosition.new(@board.copy, pieces, @side_to_move, en_passant_target) 
      end

      def move!(move)  # where do we get the color?
        # move.position => previous position
        # self => position we want to mutate
        p, b = self, self.board
        piece = p.pieces[p.side_to_move][move.coordinates]
        b[move.target[0],move.target[1]] = b[piece.position[0],piece.position[1]]
        b[piece.position[0], piece.position[1]] = nil
        # puts move.to_s
        # self.board.print
        new_coordinates = Movement::coordinates(move.target[0],move.target[1])
        p.pieces[p.side_to_move][new_coordinates] = piece
        p.pieces[p.side_to_move].delete(move.coordinates)

        if move.options[:en_passant_capture]
          b[piece.position[0], move.target[1]] = nil
          p.pieces[side_to_move].delete(Movement::coordinates(piece.position[0], move.target[1]))
          p.en_passant_target = nil
        elsif move.options[:en_passant_target]
          p.en_passant_target = [move.target[0], move.target[1]]
        end
        piece.position = [move.target[0],move.target[1]]
      end

    end

  end
end




