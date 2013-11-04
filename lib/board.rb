 
module Application

  class Board
    include Enumerable

    @squares = []

    def each
      @squares.each { |row| yield(row) }
    end

    def initialize # generates a representation of an empty chessboard.
                                                                                    # row  board #
      @squares = [ [ :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX ],  # 0       
                   [ :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX ],  # 1    
                   [ :XX, :XX, nil, nil, nil, nil, nil, nil, nil, nil, :XX, :XX ],  # 2    1
                   [ :XX, :XX, nil, nil, nil, nil, nil, nil, nil, nil, :XX, :XX ],  # 3    2
                   [ :XX, :XX, nil, nil, nil, nil, nil, nil, nil, nil, :XX, :XX ],  # 4    3
                   [ :XX, :XX, nil, nil, nil, nil, nil, nil, nil, nil, :XX, :XX ],  # 5    4
                   [ :XX, :XX, nil, nil, nil, nil, nil, nil, nil, nil, :XX, :XX ],  # 6    5
                   [ :XX, :XX, nil, nil, nil, nil, nil, nil, nil, nil, :XX, :XX ],  # 7    6
                   [ :XX, :XX, nil, nil, nil, nil, nil, nil, nil, nil, :XX, :XX ],  # 8    7
                   [ :XX, :XX, nil, nil, nil, nil, nil, nil, nil, nil, :XX, :XX ],  # 9    8
                   [ :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX ],  # 10   
                   [ :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX ] ] # 11   
            # column  0    1    2    3    4    5    6    7    8    9    10   11
            # letter            A    B    C    D    E    F    G    H
    end

    def setup  # sets the chessboard to its initial configuration at start of game.
                                                                                    # row  board #
      @squares = [ [ :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX ],  # 0       
                   [ :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX ],  # 1    
                   [ :XX, :XX, :wR, :wN, :wB, :wQ, :wK, :wB, :wN, :wR, :XX, :XX ],  # 2    1
                   [ :XX, :XX, :wP, :wP, :wP, :wP, :wP, :wP, :wP, :wP, :XX, :XX ],  # 3    2
                   [ :XX, :XX, nil, nil, nil, nil, nil, nil, nil, nil, :XX, :XX ],  # 4    3
                   [ :XX, :XX, nil, nil, nil, nil, nil, nil, nil, nil, :XX, :XX ],  # 5    4
                   [ :XX, :XX, nil, nil, nil, nil, nil, nil, nil, nil, :XX, :XX ],  # 6    5
                   [ :XX, :XX, nil, nil, nil, nil, nil, nil, nil, nil, :XX, :XX ],  # 7    6
                   [ :XX, :XX, :bP, :bP, :bP, :bP, :bP, :bP, :bP, :bP, :XX, :XX ],  # 8    7
                   [ :XX, :XX, :bR, :bN, :bB, :bQ, :bK, :bB, :bN, :bR, :XX, :XX ],  # 9    8
                   [ :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX ],  # 10   
                   [ :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX ] ] # 11   
            # column  0    1    2    3    4    5    6    7    8    9    10   11
            # letter            A    B    C    D    E    F    G    H
    end

    def copy # return a deep copy of self.
      board = Board.new
      @squares[2..9].each_with_index do |row, row_index|
        row[2..9].each_with_index do |sym, column_index|
          board[row_index, column_index] = sym
        end
      end
      return board
    end

    def to_sym(row,column)
      [nil, nil, :a, :b, :c, :d, :e, :f, :g, :h, nil, nil ]
    end

    def [](row,column)
      @squares[row][column]
    end

    def []=(row,column, value)
      @squares[row][column] = value
    end

    def empty?(row,column)
      @squares[row][column] == nil
    end

    def out_of_bounds?(row,column)
      @squares[row][column] == :XX
    end

    def occupied?(row,column)
      sym = @squares[row][column]
      sym != nil && sym != :XX
    end

    def enemy?(row,column,color)
      if occupied?(row,column)
        return true if @squares[row][column][0].to_sym != color
      end
      false
    end

    def pseudo_legal?(row, column, color)
      if empty?(row, column) || enemy?(row, column, color)
        true
      else
        false
      end
    end

    def move!(row, column, advance)  # should accept a move object/array

      @squares[row + advance[0]][column + advance[1]] = @squares[row][column]
      @squares[row][column] = nil
    end

    def place_pieces(pieces) #place all pieces specified onto the board.
      pieces.each do |piece|
        @squares[piece.position[0]][piece.position[1]] = piece.symbol
      end
    end

    def print
      puts "-" * 41
      @squares[2..9].each do |row|
        line = []
        row.each do |square|
          if square == nil 
            line << "  "
          elsif square != :XX
            line << square.to_s
          end
        end
        puts "| " + line.join(" | ") + " |"
        puts "-" * 41
      end
      puts "\n"
    end
    
  end
end