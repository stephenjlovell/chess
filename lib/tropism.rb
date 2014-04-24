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
  module Tropism

    # The Tropism module

    # Replace with bitwise equivalents.
    def self.row(sq)
      sq & 7
    end

    def self.column(sq)
      sq >> 3
    end

    # Also called Taxicab Distance.  Returns a value between 1 (min. distance) and 14 (max. distance)
    def self.manhattan_distance(from, to)
      (row(from)-row(to)).abs + (column(from)-column(to)).abs
    end # distance between 1 and 14

    # Returns 1 (maximum bonus) at minimum distance, and 0 (no bonus) at max distance.
    def self.manhattan_distance_ratio(from, to)
      distance = manhattan_distance(from, to)
      -distance/13.0 + 14.0/13.0
    end

    # Base bonuses are scaled so that total king tropism eval. component
    # is around 5% of total material value.
    BASE_BONUS_RATIO = 0.15
    BASE_BONUS = [  Pieces::PIECE_VALUES[:P]*BASE_BONUS_RATIO,  #  15.00
                    Pieces::PIECE_VALUES[:N]*BASE_BONUS_RATIO,  #  48.00
                    Pieces::PIECE_VALUES[:B]*BASE_BONUS_RATIO,  #  49.95
                    Pieces::PIECE_VALUES[:R]*BASE_BONUS_RATIO,  #  76.50
                    Pieces::PIECE_VALUES[:Q]*BASE_BONUS_RATIO,  # 132.00
                    0.0  ]                                      # 0.0
      

    # Create a 64 x 64 x 6 table containing bonuses for each piece type and from/to square combination.
    DIST = Array.new(64) do |from| 
      Array.new(64) do |to| 
        BASE_BONUS.map {|bonus| (bonus*manhattan_distance_ratio(from, to)).round.to_i }
      end
    end

    def self.get_bonus(piece_id, threat_sq, king_sq)
      DIST[threat_sq][king_sq][(piece_id>>1)&7]
    end

  end
end






















