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


    def self.create_distance_table
      locations = Chess::Location::valid_locations
      hsh = create_location_hash(locations)
      hsh.each { |loc, value| hsh[loc] = create_location_hash(locations) }
      populate_distance_table(locations, hsh)
      return hsh
    end

    def self.create_location_hash(locations)
      hsh = {}
      locations.each { |loc| hsh[loc] = nil }
      return hsh
    end

    def self.populate_distance_table(locations, hsh)
      locations.each do |from|
        locations.each do |to|
          hsh[from][to] = create_bonus_table(from, to)
        end
      end
    end

    # Returns a value between 1 (min. distance) and 7 (max. distance)
    def self.chebyshev_distance(from, to)
      Chess::max((to.r - from.r).abs, (to.c - from.c).abs)
    end

    # Returns 1 (maximum bonus) at minimum distance, and 0 (no bonus) at max distance.
    def self.chebyshev_distance_ratio(from, to)
      distance = chebyshev_distance(from, to)
      -distance/6.0 + 7.0/6.0
    end

    # Also called Taxicab Distance.  Returns a value between 1 (min. distance) and 14 (max. distance)
    def self.manhattan_distance(from, to)
      ((to.r - from.r).abs + (to.c - from.c).abs)
    end # distance between 1 and 14

    # Returns 1 (maximum bonus) at minimum distance, and 0 (no bonus) at max distance.
    def self.manhattan_distance_ratio(from, to)
      distance = manhattan_distance(from, to)
      -distance/13.0 + 14.0/13.0
    end

    # Base bonuses are scaled so that total king tropism eval. component
    # is around 5% of total material value.
    BASE_BONUS_RATIO = 0.15
    BASE_BONUS = {  P: Pieces::PIECE_VALUES[:P]*BASE_BONUS_RATIO,  #  15.00
                    N: Pieces::PIECE_VALUES[:N]*BASE_BONUS_RATIO,  #  48.00
                    B: Pieces::PIECE_VALUES[:B]*BASE_BONUS_RATIO,  #  49.95
                    R: Pieces::PIECE_VALUES[:R]*BASE_BONUS_RATIO,  #  76.50
                    Q: Pieces::PIECE_VALUES[:Q]*BASE_BONUS_RATIO,  # 132.00
                    K: 0.0 } # 0.0


    # Each piece is awarded a bonus scaled based on how close it is to the enemy king.
    def self.create_bonus_table(from, to)
      hsh = {}
      distance = manhattan_distance_ratio(from, to)
      BASE_BONUS.each do |key, bonus| 
        hsh[key] = (bonus*distance).round.to_i
      end
      return hsh 
    end

    # Create a 64 x 64 x 6 table containing bonuses for each piece type and from/to square combination.
    DIST = create_distance_table  

    def self.get_bonus(piece, piece_loc, king_loc)
      DIST[piece_loc][king_loc][piece.class.type]
    end

  end
end






















