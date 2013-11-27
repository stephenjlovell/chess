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

    class Move
      attr_reader :position, :square, :target, :capture_value, :options

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

    class Location
      attr_accessor :r, :c

      def initialize(*args)  # should accept and process a single string or pair of coordinates.
        if args.length == 1
          @r, @c = args[0][1].to_i + 1, LETTER_TO_NUMBER[args[0][0]]
        elsif args.length == 2
          @r, @c = *args
        end
      end

      def copy
        self.class.new(@r, @c)
      end

      def eql?(other)
        @r == other.r && @c == other.c
      end

      alias :== :eql? 

      def hash
        to_a.hash
      end

      def to_s  # replaces Movement::square
        (NUMBER_TO_LETTER[@c]) + (@r - 1).to_s
      end

      def to_a
        [@r, @c]
      end

    end

    def self.square(row,column)
      (NUMBER_TO_LETTER[column]) + (row - 1).to_s
    end

    def self.coordinates(square)
      return square[1].to_i + 1, LETTER_TO_NUMBER[square[0]]
    end

    # Mixin methods:

    def get_moves # returns a sorted array of all possible moves for the current player.
      moves = []
      @pieces[@side_to_move].each { |square, piece| moves += piece.get_moves(self) }
      moves += get_castles
      sort_moves(moves)
      return moves
    end

    def sort_moves(moves)
      moves.sort! { |x,y| y.capture_value <=> x.capture_value }
      # also sort non-captures by Killer Heuristic
    end

    def create_position(move) # returns a new position object representing the game state
      pos = self.copy         # that results from the current player taking the specified move.
      if move.options[:castle] && move.options[:castle] != {}
        pos.castle!(move)
      else
        pos.move!(move)
      end
      pos.previous_move = move
      pos.side_to_move = @side_to_move == :w ? :b : :w
      return pos
    end

    def get_castles
      castles = []
      hsh = @options[:castle]
      if hsh
        row = BACK_ROW[@side_to_move] 
        if hsh[:low]
          if @board.empty?(row, 3) && @board.empty?(row, 4) && @board.empty?(row, 5) # castling permitted on low side.
            castles << Move.new(self, Movement::square(row,6), [row,2], 0, castle: :low)
          end
        end
        if hsh[:high]  
          if @board.empty?(row, 7) && @board.empty?(row, 8) # castling permitted on high side.
            castles << Move.new(self, Movement::square(row,6), [row,9], 0, castle: :high)
          end
        end
      end
      return castles
    end

    def castle!(move)
      options = move.options[:castle]
      king = @pieces[@side_to_move][move.square]
      rook = @pieces[@side_to_move][Movement::square(*move.target)]
      row = BACK_ROW[@side_to_move]
      if options[:low]
        king_column, rook_column = 4, 5
      elsif options[:high]
        king_column, rook_column = 7, 8
      end
      relocate_piece!(king.square,[row, king_column])
      relocate_piece!(rook.square,[row, rook_column])
    end

    def move!(move) # updates self by performing the specified move.
      piece = @pieces[self.side_to_move][move.square]
      self.relocate_piece!(move.square, move.target)
      self.set_en_passant_flag!(piece, move)
      self.promote_pawns!
      self.set_castle_flag!(move)
    end

    def relocate_piece!(old_square,target)
      enemy = @side_to_move == :w ? :b : :w
      piece = @pieces[@side_to_move][old_square]
      @pieces[@side_to_move].delete(old_square)
      new_square = Movement::square(*target)
      @pieces[enemy].delete(new_square) if @pieces[enemy]
      @pieces[@side_to_move][new_square] = piece
      piece.position = [*target]
      @board[*(Movement::coordinates(old_square))] = nil
      @board[*target] = piece.symbol
    end

    def set_en_passant_flag!(piece, move)
      if move.options[:en_passant_capture]
        @board[piece.position[0], move.target[1]] = nil
        @pieces[side_to_move].delete(Movement::square(piece.position[0], move.target[1]))
        @options.delete(:en_passant_target)
      elsif move.options[:en_passant_target]
        @options[:en_passant_target] = [move.target[0], move.target[1]]
      end
    end

    def set_castle_flag!(move) # removes the appropriate castling option when Rook or King moves.
      case move.square
      when "a1", "a8" # if left side rook moved, no longer available for castling.
        self.options[:castle].delete(:low) if self.options[:castle]
      when "h1", "h8" # if right side rook moved, no longer available for castling.
        self.options[:castle].delete(:high) if self.options[:castle]
      when "e1", "e8" # if king is moved, castling no longer permitted.
        self.options.delete(:castle) if self.options[:castle]
      end
    end

    def promote_pawns! # called via move! method
      if side_to_move == :w
        (2..9).each { |column| promote_pawn!(9, column) if @board[9, column] == :wP }
      else
        (2..9).each { |column| promote_pawn!(2, column) if @board[2, column] == :bP }
      end
    end

    def promote_pawn!(row, column)
      square = Movement::square(row, column)
      @board[row,column] = (@side_to_move.to_s + "Q").to_sym
      @pieces[@side_to_move][square] = Pieces::Queen.new(row, column, @side_to_move)
    end

  end
end



