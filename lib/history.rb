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

require './lib/location.rb'

module Chess
  module History

    # This module implements the History Heuristic, used to sort non-killer quiet moves.

    class HistoryTable
      def initialize
        @table = create_history_table
      end

      def clear
        @table.each do |sym, locations|
          locations.each do |to, nodecount|
            @table[sym][to] = 0
          end
        end
      end

      def [](symbol)
        @table[symbol]
      end

      # Some programs increment the table values by b^(depth), where b is some estimate of the average
      # branching factor for the program. Since the exact subtree node count is returned by each alpha-beta
      # call, this is unnecessary. Use the exact nodecount to increment the history counter.
      def store(move, nodecount)
        @table[move.piece.symbol][move.to] += nodecount
      end

      private
      # Create a 12 x 64 table associating piece symbol and square with an integer history counter.
      def create_history_table
        hsh = {}
        [:wP, :wN, :wB, :wR, :wQ, :wK, :bP, :bN, :bB, :bR, :bQ, :bK].each do |sym|
          hsh[sym] = create_locations_table
        end
        return hsh
      end

      def create_locations_table
        hsh = {}
        Chess::Location::valid_locations.each do |to|
          hsh[to] = 0
        end
        return hsh
      end
    end

  end
end



















