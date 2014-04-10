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

require './lib/utilities.rb'
 
module Chess
  module Bitboard

    SQUARE_KEYS = 64.times.map { |n| 1>>n }

    def self.manhattan_distance(from, to)
      (get_row(from)-get_row(to)).abs + (get_column(from)-get_column(to)).abs
    end

    # def self.get_row(sq)  # rank
    #   sq >> 3
    # end

    # def self.get_column(sq)  # file
    #   sq & 7
    # end

    # def self.get_key(sq)
    #   SQUARE_KEYS[sq]
    # end

    # def self.on_board?(sq)
    #   (1<<sq) & UNI_MASK != 0
    # end

    def self.print_bitboard(x, square=nil)
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

  end
end








