
module Application
  module Pieces

    class Piece
      # this class will define aspects common to all chess pieces.
      attr_reader :color
      attr_reader :symbol

      def initialize(color, x, y) # :b or :w
        @color = color
        @symbol = (@color.to_s + self.class.type.to_s).to_sym if self.class.type
        @position = PiecePosition.new(x,y)
      end

    end

    class Pawn < Piece
      def self.value
        1.0
      end

      def self.type
        :P
      end

    end

    class Knight < Piece

      def self.value
        3.2
      end

      def self.type
        :N
      end

    end

    class Bishop < Piece
      
      VALUE = 10.0/3.0
      def self.value
        VALUE
      end

      def self.type
        :B
      end

    end

    class Rook < Piece

      def self.value
        5.1
      end

      def self.type
        :R
      end

    end

    class Queen < Piece

      def self.value
        8.8
      end

      def self.type
        :Q
      end

    end

    class King < Piece

      def self.value
        1000.0
      end

      def self.type
        :K
      end

    end

    def self.create_piece_by_sym(sym, x, y)
      color, type = split_symbol(sym)
      case type
      when :P
        return Pawn.new(color, x,y)
      when :R
        return Rook.new(color, x,y)
      when :N
        return Knight.new(color, x,y)
      when :B
        return Bishop.new(color, x,y)
      when :Q
        return Queen.new(color, x,y)
      when :K
        return King.new(color, x,y)
      end
    end

    def self.split_symbol(sym)
      color = sym[0].to_sym
      type = sym[1].to_sym
      return color, type
    end

  end
end

