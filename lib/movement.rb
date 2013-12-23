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

    NUMBER_TO_LETTER = { 2 => "a", 3 => "b", 4 => "c", 5 => "d", 
                         6 => "e", 7 => "f", 8 => "g", 9 => "h" }
    LETTER_TO_NUMBER = { "a" => 2, "b" => 3, "c" => 4, "d" => 5,
                         "e" => 6, "f" => 7, "g" => 8, "h" => 9 }

    BACK_ROW = { w: 2, b: 9 }

    class Location
      attr_reader :r, :c
      
      def initialize(r,c)
        @r, @c = r,c
      end

      def eql?(other)
        @r.eql?(other.r) && @c.eql?(other.c)
      end

      alias :== :eql? 

      def +(arr)
        self.class.new(@r+arr[0], @c+arr[1])
      end

      def hash
        to_a.hash
      end

      def copy
        self.class.new(@r, @c)
      end

      def to_s
        (NUMBER_TO_LETTER[@c]) + (@r - 1).to_s
      end

      def to_sym
        to_s.to_sym
      end

      def to_a
        [@r, @c]
      end
    end

    class Move
      attr_reader :position, :from, :to, :capture_value

      def initialize(position, from, to, capture_value)
        @position, @from, @to, @capture_value = position, from, to, capture_value
      end

      def to_s
        "#{@position.board[@from].to_s} #{@from.to_s} to #{@to.to_s}"
      end

      def create_position        # returns a new position object representing the game state
        pos = @position.copy     # that results from the current player taking the specified move.
        move!(pos)
        pos.previous_move = self
        pos.side_to_move = @position.side_to_move == :w ? :b : :w
        return pos
      end

      def move!(pos) # updates self by performing the specified move.
        # begin
          pos.set_castle_flag!(@from) if pos.options[:castle]
          pos.relocate_piece!(@from, @to)
          pos.promote_pawn!(@to)
          pos.options.delete(:en_passant_target) if pos.options
        # rescue
        #   print "#from:{@from} to:#{@to} \n"
        # ensure
          
        # end
      end
    end

    class Castle < Move
      attr_reader :position, :from, :to, :side

      FROM_COL = { low:  { king: 6, rook: 2 },
                   high: { king: 6, rook: 9 } }
      TO_COL = { low:  { king: 4, rook: 5 },
                 high: { king: 8, rook: 7 } }

      def initialize(position, side)
        @position, @side = position, side
      end

      def move!(pos)
        pos.options = nil  # remove castle and en-passant flag
        row = BACK_ROW[pos.side_to_move]        
        king_from = Location.new(row, FROM_COL[@side][:king])
        king_to = Location.new(row, TO_COL[@side][:king])
        rook_from = Location.new(row, FROM_COL[@side][:rook])
        rook_to = Location.new(row, TO_COL[@side][:rook])
        pos.relocate_piece!(king_from, king_to)
        pos.relocate_piece!(rook_from, rook_to)
      end

    end

    class EnPassantAttack < Move

      def initialize(position, from, to)
        @position, @from, @to, @capture_value = position, from, to, 1.0
      end

      def move!(pos)
        pos.relocate_piece!(@from, @to)
        target = Location.new(@from.r, @to.c)
        pos.board[target] = nil
        pos.pieces[position.side_to_move].delete(target)
        pos.options.delete(:en_passant_target)
      end
    end

    class EnPassantTarget < Move

      def initialize(position, from, to)
        @position, @from, @to, @capture_value = position, from, to, 0.0
      end
      
      def move!(pos)
        pos.relocate_piece!(@from, @to)
        @position.options[:en_passant_target] = @to.copy
      end
    end

    # Module helper methods:

    def self.to_location(str)
      Location.new(str[1].to_i + 1, LETTER_TO_NUMBER[str[0]])
    end

    # Mixin methods (included in Position object):

    def moves # returns a sorted array of all possible moves for the current player.
      moves = []
      active_pieces.each { |key, piece| moves += piece.get_moves(key,self) }
      moves += get_castles if @options[:castle]  # disable castles for now.
      sort_moves(moves)
      return moves
    end

    def sort_moves(moves)
      moves.sort! { |x,y| y.capture_value <=> x.capture_value }
      # also sort non-captures by Killer Heuristic?
    end

    def get_castles
      castles = []
      hsh = @options[:castle]
      row = BACK_ROW[@side_to_move] 
      if hsh[:low]
        if @board.empty?(Location.new(row, 3)) && @board.empty?(Location.new(row, 4)) && 
           @board.empty?(Location.new(row, 5))
          castles << Castle.new(self, :low)  # castling permitted on low side.
        end
      end
      if hsh[:high]  
        if @board.empty?(Location.new(row, 7)) && @board.empty?(Location.new(row, 8))
          castles << Castle.new(self, :high)  # castling permitted on high side.
        end
      end
      return castles
    end

    def relocate_piece!(from, to)
      enemy = @side_to_move == :w ? :b : :w
      piece = active_pieces[from]
      active_pieces.delete(from)
      @pieces[enemy].delete(to) 
      active_pieces[to] = piece
      @board[from] = nil
      @board[to] = piece.symbol
    end

    def set_castle_flag!(from) # removes the appropriate castling option when Rook or King moves.
      # puts from
      # puts active_pieces[from]
      type = active_pieces[from].class.type
      if type == :R
        if from == Location.new(BACK_ROW[@side_to_move],2)
          options[:castle].delete(:low)
        elsif from == Location.new(BACK_ROW[@side_to_move],9)
          options[:castle].delete(:high)
        end
      elsif type == :K
        options.delete(:castle)
      end
    end

    PAWN_PROMOTION = { wP: :wQ, bP: :bQ }
    def promote_pawn!(to) # called via move! method
      enemy = @side_to_move == :w ? :b : :w
      type = active_pieces[to]
      if to.r == BACK_ROW[enemy] && type == :P
        @board[to] = PAWN_PROMOTION[@side_to_move]
        active_pieces[to] = Pieces::Queen.new(@side_to_move)
      end
    end

  end
end



