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
      
      attr_accessor :board, :pieces,  :side_to_move, :enemy, :halfmove_clock, :previous_move, :options, :hash
      # option flags: :en_passant_target, :castle

      def initialize(board, pieces, side_to_move, halfmove_clock, previous_move = nil, options = {})
        @board, @pieces, @side_to_move, @previous_move = board, pieces, side_to_move, previous_move
        @options, @hash = options, nil
        @enemy = @side_to_move == :w ? :b : :w
      end

      def setup
        @board = Application::Board.allocate
        @board.setup
        @pieces = Pieces::setup(board)
        @side_to_move = :w  # white always goes first.
        @options = {}
        @options[:castle] = { low: true, high: true }
        @hash = get_initial_hash
        return self
      end

      def active_pieces
        @pieces[@side_to_move]
      end

      def enemy_pieces
        @pieces[@enemy]
      end

      def value
        @value ||= Evaluation::evaluate(self)
      end

      def value=(value)
        @value = value
      end

      def in_check?
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
        @board.king_in_check?(@enemy)
      end

      def avoids_check?(from, to)
        @board.avoids_check?(from, to, @side_to_move)
      end

      def copy # perform a deep copy of self.
        new_pieces = { w: {}, b: {} }
        options = Marshal.load(Marshal.dump(@options))  # expensive operation. replace options hash with object properties.
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

      def tactical_edges(pv_move=nil)
        in_check? ? get_moves : get_moves.select{ |m| m.capture_value > 0.0 }
      end

      def get_children
        get_moves.collect { |m| m.create_position }
      end

      def get_moves(pv_move=nil) # returns a sorted array of all possible moves for the current player.
        unless @moves
          @moves = []
          active_pieces.each { |key, piece| @moves += piece.get_moves(key, self) }
          @moves += get_castles if !in_check? && @options[:castle]
          sort_moves!(@moves, pv_move)
        end
        return @moves      
      end
      alias :edges :get_moves

      def sort_moves!(moves, pv_move)
        moves.sort! { |x,y| y.capture_value <=> x.capture_value }  # also sort non-captures by Killer Heuristic?
        # if pv_move
        #   pv_hash = pv_move.hash
        #   puts "previous move: #{@previous_move}"
        #   puts "pv_hash: #{pv_move.to_s}"
        #   moves.each { |m| puts "#{m.to_s}" }

        #   moves.sort! do |x,y|
        #     if x.hash == pv_hash
        #       1
        #     elsif y.hash == pv_hash
        #       -1
        #     else
        #       0
        #     end
        #   end
        # end
        # The block must implement a comparison between x and y, and return -1, 
        # when x follows y, 0 when x and y are equivalent, or +1 if y follows x.
      end

      def get_initial_hash
        key = 0
        bstr = Memory::BSTR
        @board.each_square_with_location do |r, c, sym|
          bstr[r-2][c-2][sym].unpack('L*').each { |i| key ^= i } unless sym.nil? 
        end  # unpack to 64-bit unsigned long ints and merge into key via bitwise XOR.
        return key
      end

    end

  end
end




