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
  module Bitboard

    require './ext/ruby_chess'

    class PiecewiseBoard  # This definition adds some additional methods to the PiecewiseBoard class
                          # provided by board.c

      def initialize(sboard=nil)
        setup(sboard) unless sboard.nil?
      end

      def print
        COLORS.each do |color|
          Pieces::PIECE_TYPES.each do |type|
            puts "\n", (color.to_s + type.to_s), "\n"
            print_bitboard(@bitboards[color][type])
          end
          puts "\n", color.to_s + " placement", "\n"
          print_bitboard(@occupied[color])
        end    
      end

      def print_bitboard(x, square=nil)
        str = x.to_s(2)
        str = "0"*(64-str.length) + str
        puts "   0 1 2 3 4 5 6 7"
        puts " -----------------"
        i=7
        str.reverse.split(//).each_slice(8).reverse_each do |row| 
          puts "#{i}| #{row.join(" ").gsub("1", Chess::colorize("1",32))}" 
          i-=1
        end
        puts "\n"
      end

      private

      def setup(sboard)
        @bitboards = { w: { P: 0, N: 0, B: 0, R: 0, Q: 0, K: 0 }, 
                       b: { P: 0, N: 0, B: 0, R: 0, Q: 0, K: 0 } }
        @occupied = { w: 0, b: 0 }

        sboard.flatten.each_with_index do |sym, i| 
          unless sym.nil? || sym == :XX
            @bitboards[Pieces::PIECE_COLOR[sym]][Pieces::PIECE_TYPE[sym]] |= (1<<i)
          end 
        end
        @occupied[:w] = @bitboards[:w].each.inject(0) {|all, (t, bb)| all |= bb }
        @occupied[:b] = @bitboards[:b].each.inject(0) {|all, (t, bb)| all |= bb }
      end

    end

    PiecewiseBoard.new(Board.new).print

  end
end







