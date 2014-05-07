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
require './ext/ruby_chess' 

module Chess
  module Bitboard

    class PiecewiseBoard  # This definition adds some additional methods to the PiecewiseBoard class
                          # provided by board.c

      # initialize method defined in C extension. 

      def print
        Pieces::PIECE_ID.each do |sym, piece_id|
          puts "\n#{sym}\n"
          Chess::print_bitboard(get_bitboard(piece_id))
        end
        COLORS.each do |color|
          puts "\n #{color} placement\n"
          Chess::print_bitboard(get_occupancy(color))
        end 
      end

      private

      def setup(sboard)
        sboard.each_with_index do |piece_id, sq| 
          unless piece_id == 0
            add_square(piece_id, sq) 
          end
        end
      end
      
    end


  end
end







