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

    BACK_ROW = { w: 2, b: 9 }
    PAWN_PROMOTION = { w: :wQ, b: :bQ }

    class Move
      attr_reader :position, :from, :to, :capture_value

      def initialize(position, from, to, capture_value)
        @position, @from, @to, @capture_value, @hash = position, from, to, capture_value, nil
      end

      def to_s
        "#{@position.board[@from].to_s} #{@from.to_s} to #{@to.to_s}"
      end

      # def copy
      #   self.class.new(@position.copy, @from, @to, @capture_value)
      # end

      def create_position        # returns a new position object representing the game state
        pos = @position.copy     # that results from the current player taking the specified move.
        move!(pos)
        pos.previous_move = self
        pos.side_to_move = @position.side_to_move == :w ? :b : :w
        pos.hash = @position.hash ^ self.hash 
        return pos
      end

      def move!(pos) # updates self by performing the specified move.
        pos.set_castle_flag!(@from) if pos.options[:castle]
        pos.relocate_piece!(@from, @to)
        pos.options.delete(:en_passant_target) if pos.options
      end

      def hash
        unless @hash
          key = 0
          bstr = Memory::BSTR
          board = @position.board
          sym_from = board[from]
          # if a piece is being captured, XOR out the bytestring value for its location:
          bstr[to.r-2][to.c-2][board[to]].unpack('L*').each { |i| key ^= i } unless board.empty?(to)
          @hash = hash_piece(from, to, sym_from) ^ key
        end
        return @hash
      end

      private
      def hash_piece(from, to, sym)
        key = 0
        bstr = Memory::BSTR
        board = @position.board
        # XOR out the bytestring value for the piece being moved:        
        bstr[from.r-2][from.c-2][sym].unpack('L*').each { |i| key ^= i }
        # XOR in the bytestring value for the moved piece at its new location:
        bstr[to.r-2][to.c-2][sym].unpack('L*').each { |i| key ^= i }
        return key
      end

    end


    class PawnMove < Move
      def move!(pos)
        super(pos)
        pos.promote_pawn!(@to)
      end
    end


    class Castle < Move
      attr_reader :side

      FROM_COL = { low:  { king: 6, rook: 2 },
                   high: { king: 6, rook: 9 } }
      TO_COL = { low:  { king: 4, rook: 5 },
                 high: { king: 8, rook: 7 } }

      def initialize(position, side)
        @position, @side, @capture_value = position, side, 0.0
      end

      def move!(pos)
        pos.options = nil  # remove castle and en-passant flag
        row = BACK_ROW[pos.side_to_move]        
        king_from = Location::get_location(row, FROM_COL[@side][:king])
        king_to = Location::get_location(row, TO_COL[@side][:king])
        rook_from = Location::get_location(row, FROM_COL[@side][:rook])
        rook_to = Location::get_location(row, TO_COL[@side][:rook])

        pos.relocate_piece!(king_from, king_to)
        pos.relocate_piece!(rook_from, rook_to)
      end

      def hash
        key = 0
        board = @position.board
        king_from = Location::get_location(row, FROM_COL[@side][:king])
        king_to = Location::get_location(row, TO_COL[@side][:king])
        rook_from = Location::get_location(row, FROM_COL[@side][:rook])
        rook_to = Location::get_location(row, TO_COL[@side][:rook])
        key ^ hash_piece(king_from, king_to, board[king_from]) ^ 
              hash_piece(rook_from, rook_to, board[rook_from])
        return key
      end

      def to_s

      end

    end

    class EnPassantAttack < Move
      def initialize(position, from, to, capture_value=1.0)
        @position, @from, @to, @capture_value = position, from, to, capture_value
      end

      def move!(pos)
        pos.relocate_piece!(@from, @to)
        target = Location::get_location(@from.r, @to.c)
        pos.board[target] = nil
        pos.pieces[pos.side_to_move].delete(target)
        pos.options.delete(:en_passant_target)
      end

      def hash
        unless @hash
          key = 0
          bstr = Memory::BSTR
          board = @position.board
          sym_from = board[from]
          target = Location::get_location(@from.r, @to.c)
          # if a piece is being captured, XOR out the bytestring value for its location:
          bstr[target.r-2][target.c-2][board[target]].unpack('L*').each { |i| key ^= i }
          @hash = hash_piece(from, to, sym_from) ^ key
        end
        return @hash
      end

    end

    class EnPassantTarget < Move
      def initialize(position, from, to, capture_value=0.0)
        @position, @from, @to, @capture_value = position, from, to, capture_value
      end
      
      def move!(pos)
        pos.relocate_piece!(@from, @to)
        pos.options[:en_passant_target] = @to
      end
    end

    # Module helper methods:


    # Mixin methods (included in Position object):

    def get_castles
      castles = []
      hsh = @options[:castle]
      row = BACK_ROW[@side_to_move] 
      if hsh[:low]
        if @board.coordinates_empty?(row, 3) && @board.coordinates_empty?(row, 4) && 
           @board.coordinates_empty?(row, 5)
          king_from = Location::get_location(row, Castle::FROM_COL[:low][:king])
          if avoids_check?(king_from, king_from + [-1,0]) && avoids_check?(king_from, king_from + [-2,0])
            castles << Castle.new(self, :low) # king cannot move through or into check
          end
        end
      end
      if hsh[:high]  
        if @board.coordinates_empty?(row, 7) && @board.coordinates_empty?(row, 8)
          king_from = Location::get_location(row, Castle::FROM_COL[:low][:king])
          if avoids_check?(king_from, king_from + [1,0]) && avoids_check?(king_from, king_from + [2,0])
            castles << Castle.new(self, :high) # king cannot move through or into check
          end
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
      type = active_pieces[from].class.type
      if type == :R
        if from.r == BACK_ROW[@side_to_move]
          options[:castle].delete(:low) if from.c == 2
          options[:castle].delete(:high) if from.c == 9
        end
      elsif type == :K
        options.delete(:castle)
      end
    end


    def promote_pawn!(location) # called via move! method
      enemy = @side_to_move == :w ? :b : :w
      type = active_pieces[location].class.type
      if location.r == BACK_ROW[enemy] && type == :P
        @board[location] = PAWN_PROMOTION[@side_to_move]
        active_pieces[location] = Pieces::Queen.new(@side_to_move)
      end
    end

  end
end



