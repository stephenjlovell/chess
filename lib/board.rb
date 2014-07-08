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

  # The Board class stores a 'square-centric' 8x8 board representation containing an integer id 
  # for each piece in play.  A separate bitboard-based 'piece centric' board representation is stored in the
  # PiecewiseBoard class. The Board class is used to quickly determine the occupancy of a square without having 
  # to loop through each bitboard. Both the PiecewiseBoard and Board objects are incrementally updated as moves 
  # are made and unmade during Search.
  class Board
    include Enumerable
    attr_accessor :squares
   
    # sets initial configuration of board, defaulting to the opening position.
    def initialize(squares=nil)
      id = Pieces::PIECE_ID       
      @squares = squares || [ id[:wR], id[:wN], id[:wB], id[:wQ], id[:wK], id[:wB], id[:wN], id[:wR],  # 1 row
                              id[:wP], id[:wP], id[:wP], id[:wP], id[:wP], id[:wP], id[:wP], id[:wP],  # 2  
                                    0,       0,       0,       0,       0,       0,       0,       0,  # 3    
                                    0,       0,       0,       0,       0,       0,       0,       0,  # 4    
                                    0,       0,       0,       0,       0,       0,       0,       0,  # 5    
                                    0,       0,       0,       0,       0,       0,       0,       0,  # 6    
                              id[:bP], id[:bP], id[:bP], id[:bP], id[:bP], id[:bP], id[:bP], id[:bP],  # 7    
                              id[:bR], id[:bN], id[:bB], id[:bQ], id[:bK], id[:bB], id[:bN], id[:bR] ] # 8 
                          # col     A        B        C        D        E        F        G        H
      return self
    end

    def clear  # Clears all pieces from the board.
      @squares = Array.new(64, 0)
      return self
    end

    def each
      @squares.each { |s| yield(s) }
    end
    alias :each_square :each

    def [](square)
      @squares[square]
    end

    def []=(square, value)
      @squares[square] = value
    end

    def row(sq)
      sq >> 3
    end

    def column(sq)
      sq & 7
    end

    # Also called Taxicab Distance.  Returns a value between 1 (min. distance) and 14 (max. distance)
    def manhattan_distance(from, to)
      (row(from)-row(to)).abs + (column(from)-column(to)).abs
    end # distance between 1 and 14

    # Returns a value between 1 (min. distance) and 7 (max. distance)
    def self.chebyshev_distance(from, to)
      Chess::max((to.r - from.r).abs, (to.c - from.c).abs)
    end

    # Provide an initial hash for position object by merging (via XOR) the hash keys for each # piece/square.
    def hash
      each_with_index.inject(0) {|h, (id, i)| h ^= (id==0 ? 0 : Memory::psq_key(id, i)); h }
    end

    # Unicode symbols for chess pieces:
    GRAPHICS = { wP: "\u2659", wN: "\u2658", wB: "\u2657", wR: "\u2656", wQ: "\u2655", wK: "\u2654" , 
                 bP: "\u265F", bN: "\u265E", bB: "\u265D", bR: "\u265C", bQ: "\u265B", bK: "\u265A" }
                 
    def print  # prints out a visual representation of the chessboard to the console.
      i = 8
      piece_codes = Pieces::ID_TO_SYM
      puts (headings = "    A   B   C   D   E   F   G   H")
      puts (divider =  "  " + ("-" * 33))
      @squares.each_slice(8).to_a.reverse.each do |row|
        line = []
        row.each do |square|
          if square == 0 
            line << " "
          elsif square.nil?
            line << "X"
          else
            line << GRAPHICS[piece_codes[square]]
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




