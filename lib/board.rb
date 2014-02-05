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
 
module Chess
  # Unicode symbols for chess pieces:
  GRAPHICS = { wP: "\u2659", wN: "\u2658", wB: "\u2657", wR: "\u2656", wQ: "\u2655", wK: "\u2654" , 
               bP: "\u265F", bN: "\u265E", bB: "\u265D", bR: "\u265C", bQ: "\u265B", bK: "\u265A" }

  ENEMY_BACK_ROW = { w: 9, b: 2 }

  FLIP_COLOR = { w: :b, b: :w }

  class Board
    include Enumerable
    include Attack
    attr_accessor :squares

    def initialize  # sets initial configuration of board at start of game.         # row  board #
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

    def each
      each_square_with_location { |r,c,s| yield (@squares[r][c]) }
    end
    alias :each_square :each

    def each_square_with_location
      (2..9).each do |r|
        (2..9).each do |c|
          yield r, c, @squares[r][c]
        end
      end
    end

    def reverse_each_square_with_location
      (2..9).reverse_each do |r|
        (2..9).reverse_each do |c|
          yield r, c, @squares[r][c]
        end
      end
    end

    def hash # used when providing an initial hash value for position object.
      key = 0
      each_square_with_location { |r,c,s| key ^= Memory::psq_key_by_square(r,c,s) unless s.nil? }
      return key
    end

    def square(r, c)
      @squares[r][c]
    end

    def [](location)
      @squares[location.r][location.c]
    end

    def []=(location, value)
      @squares[location.r][location.c] = value
    end

    def empty?(location)
      self[location] == nil
    end

    def square_empty?(r,c)
      @squares[r][c] == nil
    end

    def on_board?(location)
      self[location] != :XX
    end

    def square_on_board?(r, c)
      @squares[r][c] != :XX
    end

    def occupied?(location)
      sym = self[location]
      sym != nil && sym != :XX
    end

    # refactor this method to reduce cost using a constant hash:

    def enemy?(location, color)      
      occupied?(location) && Pieces::PIECE_COLOR[self[location]] != color
    end

    def avoids_check?(position, from, to, color, king_location=nil)
      piece_sym = self[from]
      target_sym = self[to]
      self[from] = nil  # simulate making the specified regular move
      self[to] = piece_sym

      avoids_check = king_in_check?(position, color, king_location) == false  # No moves are legal if king has been killed.

      self[from] = piece_sym  # undo changes to board
      self[to] = target_sym
      return avoids_check
    end

    def king_in_check?(position, color, king_location=nil)
      king_location ||= position.king_location[color] # get location of king for color.
      king_attacked?(king_location, FLIP_COLOR[color])
    end

    


  end
end




