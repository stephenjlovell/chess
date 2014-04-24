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

require './lib/search.rb'

module Chess
  module Killer

    # This module implements the Killer Heuristic as a way of sorting quiet moves.

    # Each KillerEntry can hold up to three killer moves.
    KillerEntry = Struct.new(:first, :second, :third)

    class KillerTable
      def initialize
        # Create a hash table for storing killer moves indexed by depth.
        @table = (-10..60).each.inject({}) {|hsh, i| hsh[i] = KillerEntry.new; hsh }
      end

      def clear
        # @table = Array.new(20) { KillerEntry.new }
        @table.each { |depth, value| @table[depth] = KillerEntry.new }
      end

      def [](depth)
        @table[depth]
      end

      # Store a potential killer move, ensuring that each of the three slots contains a different move.
      # Moves are added and replaced in first-in, first-out order.
      def store(pos, move, depth)
        if move.quiet?
          e = @table[depth]
          unless move == e.first  # If the new move is already at the top of the list, no update needed.
            if pos.evades_check?(move) # only store legal moves in killer table.
              if move == e.second
                e.second = e.first
                e.first = move
              else
                e.third = e.second
                e.second = e.first
                e.first = move
              end
            end
          end
        end
      end

    end

  end
end



















