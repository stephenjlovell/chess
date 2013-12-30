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
      
      attr_accessor :board, :pieces,  :side_to_move, :previous_move, :options, :hash_value
      # option flags: :en_passant_target, :castle

      def initialize(board, pieces, side_to_move, previous_move = nil, options = {})
        @board = board
        @pieces = pieces   # pieces collection generated via Pieces::Setup
        @side_to_move = side_to_move
        @previous_move = previous_move
        @options = options
      end

      def setup
        @board = Application::Board.allocate
        @board.setup
        @pieces = Pieces::setup(board)
        @side_to_move = :w  # white always goes first.
        @options = {}
        @options[:castle] = { low: true, high: true }
        return self
      end

      def en_passant_target?(location)
        @options[:en_passant_target] == location
      end

      def active_pieces
        @pieces[@side_to_move]
      end

      def value
        @value ||= Evaluation::evaluate(self)
      end

      def value=(value)
        @value = value
      end

      def copy # perform a deep copy of self.
        new_pieces = { w: {}, b: {} }
        options = Marshal.load(Marshal.dump(@options))  # en passant targets should not be automatically preserved.
        @pieces.each do |color, hsh|
          @pieces[color].each do |location, piece|
            new_pieces[color][location] = piece
          end
        end
        ChessPosition.new(@board.copy, new_pieces, @side_to_move, @previous_move, options) 
      end

      def to_s
        # return a string decribing the position in Forsyth-Edwards Notation.
      end

      # should only get moves initially, then make moves separately.

      def inspect
        "<Application::Position::ChessPosition #{@board.inspect} <@pieces:#{@pieces.inspect}>, <@side_to_move:#{@side_to_move}>"
      end

      def edges  
        self.moves.collect { |m| m.create_position }
      end

      def tactical_edges
        self.moves.select{ |m| m.capture_value > 0.0}.collect{ |m| m.create_position}
      end

      def parent
        return nil if @previous_move.nil?
        @previous_move.position
      end

    end

  end
end




