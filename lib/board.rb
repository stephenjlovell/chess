
module Application

  class Board
    include Enumerable

    @squares = []

    def each
      @squares.each { |row| yield(row) }
    end

    def initialize # sets the chessboard to its initial configuration
                   # at the start of the game.                                      # row  board #
      @squares = [ [ :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX ],  # 0       
                   [ :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX ],  # 1 
                   [ :XX, :XX, :wR, :wN, :wB, :wQ, :wK, :wB, :wN, :wR, :XX, :XX ],  # 2    1
                   [ :XX, :XX, :wP, :wP, :wP, :wP, :wP, :wP, :wP, :wP, :XX, :XX ],  # 3    2
                   [ :XX, :XX, nil, nil, nil, nil, nil, nil, nil, nil, :XX, :XX ],  # 4    3
                   [ :XX, :XX, nil, nil, nil, nil, nil, nil, nil, nil, :XX, :XX ],  # 5    4
                   [ :XX, :XX, nil, nil, nil, nil, nil, nil, nil, nil, :XX, :XX ],  # 6    5
                   [ :XX, :XX, nil, nil, nil, nil, nil, nil, nil, nil, :XX, :XX ],  # 7    6
                   [ :XX, :XX, :bP, :bP, :bP, :bP, :bP, :bP, :bP, :bP, :XX, :XX ],  # 8    7
                   [ :XX, :XX, :bR, :bN, :bB, :bQ, :bK, :bB, :bK, :bR, :XX, :XX ],  # 9    8
                   [ :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX ],  # 10
                   [ :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX ] ] # 11
            # column  0    1    2    3    4    5    6    7    8    9    10   11
            # letter            A    B    C    D    E    F    G    H
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

    def enemy?(row,column,color)
      sym = @squares[row][column]
      if sym != nil && sym != :XX
        return true if sym[0].to_sym != color
      end
      return false
    end

    # def color?(sym)
    #   return nil if sym == nil || sym == :XX
    #   sym[0].to_sym
    # end
    
  end

end


