
module Application

  class Board
    include Enumerable

    @squares = []

    def each
      @squares.each { |row| yield(row) }
    end

    def initialize # sets the chessboard to its initial configuration
                   # at the start of the game.
      @squares = [ [ :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX ],  # 0
                   [ :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX ],  # 1
                   [ :XX, :wR, :wN, :wB, :wQ, :wK, :wB, :wN, :wR, :XX ],  # 2
                   [ :XX, :wP, :wP, :wP, :wP, :wP, :wP, :wP, :wP, :wP ],  # 3
                   [ :XX, nil, nil, nil, nil, nil, nil, nil, nil, :XX ],  # 4
                   [ :XX, nil, nil, nil, nil, nil, nil, nil, nil, :XX ],  # 5
                   [ :XX, nil, nil, nil, nil, nil, nil, nil, nil, :XX ],  # 6
                   [ :XX, nil, nil, nil, nil, nil, nil, nil, nil, :XX ],  # 7
                   [ :XX, :bP, :bP, :bP, :bP, :bP, :bP, :bP, :bP, :XX ],  # 8
                   [ :XX, :bR, :bN, :bB, :bQ, :bK, :bB, :bK, :bR, :XX ],  # 9
                   [ :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX ],  # 10
                   [ :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX ] ] # 11
                   #  0    1    2    3    4    5    6    7    8    9
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

  end

end


