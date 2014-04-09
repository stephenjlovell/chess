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


    class PiecewiseBoard
      attr_reader :boards

      def initialize(bitboards=nil)
        @boards = bitboards || create_bitboards 
      end

      def clear # Removes all pieces from the board
        @boards.each { |sym, bb| @boards[sym] = 0 }
      end

      def [](color)
        @boards[color]
      end

      def print
        puts "not implemented"
      end

      def print_bitboards
        @boards.each do |color, hsh|
          hsh.each do |sym, bb|
            puts color.to_s + sym.to_s
            Bitboard::print_bitboard(bb)
          end
        end
      end


      private

      def create_bitboards  # Sets initial configuration of board at start of game. 
        hsh = { w: {}, b: {} }
        hsh[:w][:P] = ROW_MASKS[1]
        hsh[:w][:N] = (1<<1) | (1<<6)
        hsh[:w][:B] = (1<<2) | (1<<5)
        hsh[:w][:R] =     1  | (1<<7)
        hsh[:w][:Q] = (1<<3)
        hsh[:w][:K] = (1<<4)
        hsh[:b][:P] = ROW_MASKS[6]
        hsh[:b][:N] = hsh[:w][:N] << 56
        hsh[:b][:B] = hsh[:w][:B] << 56
        hsh[:b][:R] = hsh[:w][:R] << 56
        hsh[:b][:Q] = hsh[:w][:Q] << 56
        hsh[:b][:K] = hsh[:w][:K] << 56
        return hsh
      end

    end

  end
end







