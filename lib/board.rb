
module Application

  class Board
    include Enumerable

    @squares = []

    def each
      @squares.each { |row| yield(row) }
    end

    def initialize # sets the chessboard to its initial configuration
                   # at the start of the game.
      @squares = [ [ :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX ],  # 0
                   [ :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX ],  # 1
                   [ :XX, :XX, :wR, :wN, :wB, :wQ, :wK, :wB, :wN, :wR, :XX, :XX ],  # 2
                   [ :XX, :XX, :wP, :wP, :wP, :wP, :wP, :wP, :wP, :wP, :wP, :XX ],  # 3
                   [ :XX, :XX, nil, nil, nil, nil, nil, nil, nil, nil, :XX, :XX ],  # 4
                   [ :XX, :XX, nil, nil, nil, nil, nil, nil, nil, nil, :XX, :XX ],  # 5
                   [ :XX, :XX, nil, nil, nil, nil, nil, nil, nil, nil, :XX, :XX ],  # 6
                   [ :XX, :XX, nil, nil, nil, nil, nil, nil, nil, nil, :XX, :XX ],  # 7
                   [ :XX, :XX, :bP, :bP, :bP, :bP, :bP, :bP, :bP, :bP, :XX, :XX ],  # 8
                   [ :XX, :XX, :bR, :bN, :bB, :bQ, :bK, :bB, :bK, :bR, :XX, :XX ],  # 9
                   [ :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX ],  # 10
                   [ :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX ] ] # 11
                   #  0    1    2    3    4    5    6    7    8    9    10   11
    end

    def [](x,y)
      @squares[x][y]
    end

    def []=(x, y, value)
      @squares[x][y] = value
    end

    def empty?(x,y)
      @squares[x][y] == nil
    end

    def out_of_bounds?(x,y)
      @squares[x][y] == :XX
    end

    def is_legal?(color, x,y)
      !out_of_bounds?(x,y) && @squares[x][y][0] != color.to_s
    end

  end

end


