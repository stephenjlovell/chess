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
      
      attr_accessor :board, :pieces,  :side_to_move, :halfmove_clock, :previous_move, :options
      # option flags: :en_passant_target, :castle

      def initialize(board, pieces, side_to_move, halfmove_clock, previous_move = nil, options = {})
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

      def active_pieces
        @pieces[@side_to_move]
      end

      def value
        @value ||= Evaluation::evaluate(self)
      end

      def value=(value)
        @value = value
      end

      def enemy
        @enemy ||= @side_to_move == :w ? :b : :w
      end

      def in_check?
        # @in_check ||= @board.king_in_check?(@side_to_move)
        if @in_check.nil?
          in_check = @board.king_in_check?(@side_to_move)
          if in_check.nil?
            self.value = -$INF  # The king is dead, long live the king.
            @in_check = true
          else 
            @in_check = in_check
          end
        else
          @in_check
        end
      end

      def enemy_in_check?
        @board.king_in_check?(enemy)
      end

      def avoids_check?(from, to)
        @board.avoids_check?(from, to, @side_to_move)
      end

      def copy # perform a deep copy of self.
        new_pieces = { w: {}, b: {} }
        options = Marshal.load(Marshal.dump(@options))  # en passant targets should not be automatically preserved.
        @pieces.each do |color, hsh|
          hsh.each do |location, piece|
            new_pieces[color][location] = piece
          end
        end
        ChessPosition.new(@board.copy, new_pieces, @side_to_move, @halfmove_clock, @previous_move, options) 
      end

      def to_s
        # return a string decribing the position in Forsyth-Edwards Notation.
      end

      def inspect
        "<Application::Position::ChessPosition <@board:#{@board.inspect}> <@pieces:#{@pieces.inspect}>, <@side_to_move:#{@side_to_move}>>"
      end

      def parent
        return nil if @previous_move.nil?
        @previous_move.position
      end

      def tactical_edges
        in_check? ? get_moves : get_moves.select{ |m| m.capture_value > 0.0 }
      end

      def get_children
        get_moves.collect { |m| m.create_position }
      end

      def get_moves # returns a sorted array of all possible moves for the current player.
        moves = []
        active_pieces.each { |key, piece| moves += piece.get_moves(key, self) }
        moves += get_castles if !in_check? && @options[:castle]
        sort_moves!(moves)
      end
      alias :edges :get_moves

    end

  end
end




