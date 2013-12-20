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
  # unicode symbols for chess pieces:
  GRAPHICS = { wP: "\u2659", wN: "\u2658", wB: "\u2657", wR: "\u2656", wQ: "\u2655", wK: "\u2654" , 
               bP: "\u265F", bN: "\u265E", bB: "\u265D", bR: "\u265C", bQ: "\u265B", bK: "\u265A" }

  class Board
    include Enumerable

    attr_writer :squares

    def initialize # generates a representation of an empty chessboard.             # row  board #
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

    def setup  # sets initial configuration of board at start of game.              # row  board #
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

    def each
      @squares.each { |row| yield(row) }
    end

    alias :each_row :each

    def each_square
      each_square_with_location { |r,c,s| yield (@squares[r][c]) }
    end

    def each_square_with_location
      (2..9).each do |r|
        (2..9).each do |c|
          yield r, c, @squares[r][c]
        end
      end
    end

    def copy # return a deep copy of self.
      board = Board.new
      each_square_with_location { |r,c,s| board[Movement::Location.new(r,c)] = s }
      return board
    end

    def coordinates(r, c)
      @squares[r][c]
    end

    def [](location)
      @squares[location.r][location.c]
    end

    def []=(location, value)
      @squares[location.r][location.c] = value
    end

    def empty?(location)
      @squares[location.r][location.c] == nil
    end

    def out_of_bounds?(location)
      @squares[location.r][location.c] == :XX
    end

    def occupied?(location)
      sym = @squares[location.r][location.c]
      sym != nil && sym != :XX
    end

    def enemy?(location, color)
      occupied?(location) && @squares[location.r][location.c][0].to_sym != color
    end

    def pseudo_legal?(location, color)
      empty?(location) || enemy?(location, color)
    end

    def king_in_check?(color)
      
    end

    def print
      i = 8
      puts (headings = "    A   B   C   D   E   F   G   H")
      puts (divider =  "  " + ("-" * 33))
      @squares[2..9].reverse_each do |row|
        line = []
        row.each do |square|
          if square == nil 
            line << " "
          elsif square != :XX
            line << GRAPHICS[square]
          end
        end
        puts "#{i} | " + line.join(" | ") + " | #{i}"
        puts divider
        i-=1
      end
      puts "#{headings}\n"
    end

  end
end