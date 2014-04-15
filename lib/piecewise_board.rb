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

    # class PiecewiseBoard

    #   def initialize(bitboards=nil)
    #     @boards = bitboards || create_bitboards 
    #   end

    #   def clear # Removes all pieces from the board
    #     @boards.each { |sym, bb| @boards[sym] = 0 }
    #   end

    #   def [](color)
    #     @boards[color]
    #   end

    #   def print
    #     puts "not implemented"
    #   end

    #   def print_bitboards
    #     @boards.each do |color, hsh|
    #       hsh.each do |sym, bb|
    #         puts color.to_s + sym.to_s
    #         Bitboard::print_bitboard(bb)
    #       end
    #     end
    #   end


    #   def print_bitboard(x, square=nil)
    #     str = x.to_s(2)
    #     str = "0"*(64-str.length) + str
    #     puts "   0 1 2 3 4 5 6 7"
    #     puts " -----------------"
    #     i=7
    #     str.reverse.split(//).each_slice(8).reverse_each do |row| 
    #       puts "#{i}| #{row.join(" ").gsub("1", Chess::colorize("1",32))}" 
    #       i-=1
    #     end
    #     puts "\n"
    #   end

    # end

  end
end







