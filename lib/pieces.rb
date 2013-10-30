
module Application
  module Pieces

    class Piece  # this class defines the common behavior of chess pieces.
      attr_reader :color, :symbol, :position

      def initialize(row, column, color) # :b or :w
        @color = color
        @symbol = (@color.to_s + self.class.type.to_s).to_sym if self.class.type
        @position = Position::PiecePosition.new(row,column)
      end

      def get_moves
        moves = []
        directions.each do |direction|
          moves += Movement::explore_direction(start,direction,color,board)
        end
        return moves
      end      
    end

    class Pawn < Piece
      #   PAWN_ATTACK = [[1,1],[1,-1]]
      #   PAWN_ADVANCE = [[1,0]]
      #   PAWN_INITIAL_ADVANCE = [[1,0],[2,0]]
      def self.value
        1.0
      end

      def self.type
        :P
      end

      def self.move_until_blocked?
        false
      end

      def self.directions
        [[1,0],[1,1][1,-1]]
      end

      def get_moves # overload the generic get_moves function provided by the Piece class.

      end

    end

    class Knight < Piece
      def self.value
        3.2
      end

      def self.type
        :N
      end

      def self.move_until_blocked?
        false
      end

      def self.directions
        [[2,1], [1,2], [-2,1], [-1,2], [-2,-1], [-1,-2], [2,-1], [1,-2]]
      end

    end

    class Bishop < Piece
      #   DIAGONALS = [[1,1],[1,-1],[-1,1],[-1,-1]]
      VALUE = 10.0/3.0
      def self.value
        VALUE
      end

      def self.type
        :B
      end

      def self.move_until_blocked?
        true
      end

    end

    class Rook < Piece
      #  SQUARES = [[1,0],[-1,0],[0,1],[0,-1]]
      def self.value
        5.1
      end

      def self.type
        :R
      end

      def self.move_until_blocked?
        true
      end

    end

    class Queen < Piece
      #   DIAGONALS = [[1,1],[1,-1],[-1,1],[-1,-1]]
      #   SQUARES = [[1,0],[-1,0],[0,1],[0,-1]]
      def self.value
        8.8
      end

      def self.type
        :Q
      end

      def self.move_until_blocked?
        true
      end

    end

    class King < Piece
    #   DIAGONALS = [[1,1],[1,-1],[-1,1],[-1,-1]]
    #   SQUARES = [[1,0],[-1,0],[0,1],[0,-1]]
      def self.value
        1000.0
      end

      def self.type
        :K
      end

      def self.move_until_blocked?
        false
      end

    end

    def self.create_piece_by_sym(row, column, sym)
      color, type = sym[0].to_sym, sym[1].to_sym
      case type
      when :P
        return Pawn.new(row, column, color)
      when :R
        return Rook.new(row, column, color)
      when :N
        return Knight.new(row, column, color)
      when :B
        return Bishop.new(row, column, color)
      when :Q
        return Queen.new(row, column, color)
      when :K
        return King.new(row, column, color)
      end
    end

  end
end

