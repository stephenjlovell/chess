
module Application
  module Pieces

    # class PieceCollection
    #   include Enumerable
    #   attr_accessor :white, :black

    #   def initialize(white = [], black = [])
    #     @white  = white
    #     @black = black
    #   end

    #   def each
    #     all.each { |piece| yield(piece) }
    #   end

    #   def all
    #     @white + @black
    #   end

    # end

    class Piece  # this class defines the common behavior of chess pieces.
      attr_reader :color 
      attr_accessor :position

      def initialize(row, column, color)
        @color = color
        @position = [row, column]
      end

      def copy # return a deep copy of self
        self.class.new(@position[0],@position[1],@color)
      end

      def symbol
        (@color.to_s + self.class.type.to_s).to_sym
      end

      def get_moves(chess_position) # returns a collection of all pseudo-legal moves for the current piece.
        moves = []                  # each move contains the piece, target square, capture value, and en_passant flag.
        self.class.directions.each do |direction|
          move = explore_direction(@position, direction, chess_position.board)
          moves += move unless move.empty?
        end
        return moves
      end

      private 

        def explore_direction(start, direction, board, moves = [] )
          target = [ start[0] + direction[0], start[1] + direction[1]]
          value = 0.0
          if board.pseudo_legal?(target[0],target[1], @color)
            if board.enemy?(target[0],target[1], @color)
              value = Pieces::get_value_by_sym(board[target[0],target[1]])
            end

            moves << [self, target, value, false]
          
            if self.class.move_until_blocked? && board.empty?(target[0], target[1])
              explore_direction(target, direction, board, moves) 
            end
          end
          return moves
        end
    end

    class Pawn < Piece

      DIRECTIONS = { w: { attack: [[1,1],[1,-1]],
                          advance: [1,0],
                          initial: [2,0],
                          enp_offset: [1,0], 
                          start_row: 3 },
                     b: { attack: [[-1,-1],[-1,1]],
                          advance: [-1,0],                               
                          initial: [-2,0],
                          enp_offset: [-1,0],  
                          start_row: 8 }, 
                     en_passant: [[0,1],[0,-1]] }

      class << self
        def value
          1.0
        end

        def type
          :P
        end

        def move_until_blocked?
          false
        end
      end

      def get_moves(chess_position) # supercedes the generic get_moves function provided by the Piece class.
        moves = []
        get_attacks(chess_position.board,moves)
        get_en_passant(chess_position,moves)
        get_advances(chess_position,moves)
        return moves
      end

      def get_attacks(board, moves)
        attacks = DIRECTIONS[@color][:attack]
        attacks.each do |pair|  # normal attacks
          target = [ @position[0] + pair[0], @position[1] + pair[1]]
          if board.enemy?(target[0], target[1], @color)
            value = Pieces::get_value_by_sym(board[target[0],target[1]])
            moves << [ self, target, value, false]
          end
        end
      end

      def get_en_passant(chess_position, moves)
        DIRECTIONS[:en_passant].each do |pair|
          target = [ @position[0] + pair[0], @position[1] + pair[1]]
          b = chess_position.board
          if b.en_passant_target?(target[0],target[1]) && b.enemy?(target[0],target[1], @color)
            offset = DIRECTIONS[@color][:enp_offset]
            move_target = [target[0] + offset[0], target[1] + offset[1] ]
            # should also store whether move is an en-passant capture
            moves << [ self, move_target, 1.0, false ] # value of en-passant capture is 1 by definition.
          end
        end
      end

      def get_advances(chess_position, moves)
        d = DIRECTIONS[@color]
        target = [ @position[0] + d[:advance][0], @position[1] + d[:advance][1] ]
        b = chess_position.board
        unless b.occupied?(target[0], target[1])
          moves << [ self, target, 0.0]
          if @position[0] == d[:start_row]
            target = [ @position[0] + d[:initial][0], @position[1] + d[:initial][1]]
            unless b.occupied?(target[0], target[1])
              moves << [ self, target, 0.0, true] # pawn is now en-passant capturable next turn only.
            end
          end
        end
      end

    end

    class Knight < Piece
      class << self
        def value
          3.2
        end

        def type
          :N
        end

        def move_until_blocked?
          false
        end

        def directions
          [[2,1], [1,2], [-2,1], [-1,2], [-2,-1], [-1,-2], [2,-1], [1,-2]]
        end
      end
    end

    class Bishop < Piece
      class << self
        VALUE = 10.0/3.0
        def value
          VALUE
        end

        def type
          :B
        end

        def move_until_blocked?
          true
        end

        def directions
          [[1,1],[1,-1],[-1,1],[-1,-1]]
        end
      end
    end

    class Rook < Piece
      class << self
        def value
          5.1
        end

        def type
          :R
        end

        def move_until_blocked?
          true
        end

        def directions
          [[1,0],[-1,0],[0,1],[0,-1]]
        end
      end
    end

    class Queen < Piece
      class << self
        def value
          8.8
        end

        def type
          :Q
        end

        def move_until_blocked?
          true
        end

        def directions
          [[1,0],[-1,0],[0,1],[0,-1],[1,1],[1,-1],[-1,1],[-1,-1]]
        end
      end
    end

    class King < Piece
      class << self
        def value
          1000.0
        end

        def type
          :K
        end

        def move_until_blocked?
          false
        end

        def directions
          [[1,0],[-1,0],[0,1],[0,-1],[1,1],[1,-1],[-1,1],[-1,-1]]
        end
      end
    end

    def self.create_piece_by_sym(row, column, sym)
      color, type = sym[0].to_sym, sym[1]
      case type
      when "P"
        return Pawn.new(row, column, color)
      when "R"
        return Rook.new(row, column, color)
      when "N"
        return Knight.new(row, column, color)
      when "B"
        return Bishop.new(row, column, color)
      when "Q"
        return Queen.new(row, column, color)
      when "K"
        return King.new(row, column, color)
      end
    end

    def self.get_value_by_sym(sym)  # will eventually want to replace this with a simple lookup table for performance.
      type = sym[1]
      case type
      when "P"
        return Pawn.value
      when "R"
        return Rook.value
      when "N"
        return Knight.value
      when "B"
        return Bishop.value
      when "Q"
        return Queen.value
      when "K"
        return King.value
      end
    end

    def self.setup(board)  # returns an array of new chess piece objects corresponding to the 
      pieces = { w: [], b: [] }         # board representation specified in board.
      board.each_with_index do |row, row_index|
        row.each_with_index do |sym, column|
          unless sym == nil || sym == :XX
            piece = self.create_piece_by_sym(row_index, column, sym) 
            pieces[piece.color] << piece
          end
        end
      end
      return pieces
    end

    def self.castle
      # allow castling
    end

  end
end

