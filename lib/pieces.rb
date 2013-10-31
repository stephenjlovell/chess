
module Application
  module Pieces

    class Piece  # this class defines the common behavior of chess pieces.
      attr_reader :color 
      attr_accessor :position

      def initialize(row, column, color) # :b or :w
        @color = color
        @position = [row, column]
      end

      def symbol
        (@color.to_s + self.class.type.to_s).to_sym
      end

      def get_sorted_moves(board)
        get_moves(board).sort { |x,y| y[2] <=> x[2] }
      end

      def get_moves(board)
        moves = []
        self.class.directions.each do |direction|
          target = explore_direction(@position, direction, board)
          moves += target unless target.empty?
        end
        return moves
      end

      private 

        def explore_direction(start, direction, board, moves = [] )
          move = [ start[0] + direction[0], start[1] + direction[1], 0.0 ]

          if board.pseudo_legal?(move[0],move[1], @color)
            if board.enemy?(move[0],move[1], @color)
              move[2] = Pieces::get_value_by_sym(board[move[0],move[1]])
            end

            moves << move
          
            if self.class.move_until_blocked? && board.empty?(move[0], move[1])
              explore_direction(move, direction, board, moves) 
            end
          end
          return moves
        end
    end

    class Pawn < Piece

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

      def get_moves(board) # override the generic get_moves function provided by the Piece class.
        [[1,0,0],[2,0,0]]  # this will take some work.
        #   PAWN_ATTACK = [[1,1],[1,-1]]
        #   PAWN_ADVANCE = [[1,0]]
        #   PAWN_INITIAL_ADVANCE = [[1,0],[2,0]]

        # pawn advance also depends on side to move.
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

      def self.directions
        [[1,1],[1,-1],[-1,1],[-1,-1]]
      end

    end

    class Rook < Piece
      def self.value
        5.1
      end

      def self.type
        :R
      end

      def self.move_until_blocked?
        true
      end

      def self.directions
        [[1,0],[-1,0],[0,1],[0,-1]]
      end
    end

    class Queen < Piece
      def self.value
        8.8
      end

      def self.type
        :Q
      end

      def self.move_until_blocked?
        true
      end

      def self.directions
        [[1,0],[-1,0],[0,1],[0,-1],[1,1],[1,-1],[-1,1],[-1,-1]]
      end
    end

    class King < Piece
      def self.value
        1000.0
      end

      def self.type
        :K
      end

      def self.move_until_blocked?
        false
      end

      def self.directions
        [[1,0],[-1,0],[0,1],[0,-1],[1,1],[1,-1],[-1,1],[-1,-1]]
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

    def self.get_value_by_sym(sym)
      type = sym[1].to_sym
      case type
      when :P
        return Pawn.value
      when :R
        return Rook.value
      when :N
        return Knight.value
      when :B
        return Bishop.value
      when :Q
        return Queen.value
      when :K
        return King.value
      end
    end

    def self.setup_pieces(board)  
      # returns an array of new chess piece objects corresponding to the 
      # board representation specified in board.
      pieces = []
      board.each_with_index do |row, row_index|
        row.each_with_index do |sym, column|
          unless sym == nil || sym == :XX
            pieces << Pieces::create_piece_by_sym(row_index, column, sym) 
          end
        end
      end
      return pieces
    end

  end
end

