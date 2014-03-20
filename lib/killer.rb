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
        # @table = Array.new(20) { KillerEntry.new }
        @table = create_killers
      end

      def clear
        # @table = Array.new(20) { KillerEntry.new }
        @table.each { |depth, value| @table[depth] = KillerEntry.new }
      end

      def [](depth)
        @table[depth]
      end

      # def sort!(moves, depth)
      #   k = @table[depth]
      #   return moves if k.first.nil?
      #   moves.sort! do |x,y|
      #     if y == k.first
      #       1
      #     elsif x == k.first
      #       -1
      #     elsif y == k.second
      #       1
      #     elsif x == k.second
      #       -1
      #     elsif y == k.third
      #       1
      #     elsif x == k.third
      #       -1
      #     else
      #       0
      #     end
      #   end        
      # end

      # Store a potential killer move, ensuring that each of the three slots contains a different move.
      # Moves are added and replaced in first-in, first-out order.
      def store(pos, move, depth)
        if move.quiet?
          e = @table[depth]
          unless move == e.first
            if pos.avoids_check?(move)
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

      private

      def create_killers
        min = Search::EXT_MAX/Search::PLY_VALUE
        hsh = {}
        (-min..10).each { |n| hsh[n*Search::PLY_VALUE] = KillerEntry.new }
        return hsh
      end

    end

  end
end



















