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

    class ChessPosition    # Complete description of the game state as of a specific turn.
      include Application::Movement
      
      attr_accessor :board, :pieces,  :side_to_move, :previous_move, :options
      # option flags: :en_passant_target, :castle

      def initialize(board, pieces, side_to_move, previous_move = nil, options = {})
        @board = board
        @pieces = pieces   # pieces collection generated via Pieces::Setup
        @side_to_move = side_to_move
        @previous_move = previous_move
        @options = options
      end

      def en_passant_target?(row, column)
        enp = @options[:en_passant_target]
        !enp.nil? && enp[0] == row && enp[1] == column
      end

      def value
        @value ||= Evaluation::evaluate(self)
      end

      def value=(value)
        @value = value
      end

      def copy # perform a deep copy of self.
        new_pieces = { w: {}, b: {} }
        options = Marshal.load(Marshal.dump(@options))
        @pieces.each do |color, square_hash|
          @pieces[color].each do |square, piece|
            new_pieces[color][square] = piece.copy
          end
        end
        ChessPosition.new(@board.copy, new_pieces, @side_to_move, @previous_move, options) 
      end

      def to_s
         # return a string decribing the position in Forsyth-Edwards Notation.
      end

      def edges
        @edges ||= self.get_moves.collect { |move| self.create_position(move) }
      end

      def parent
        return nil if previous_move.nil?
        previous_move.position
      end

    end

  end
end




