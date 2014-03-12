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

    def self.create_distance_table
      locations = Chess::Location::LOCATIONS[2..9].collect { |r| r[2..9] }.flatten
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

    # Also called Taxicab Distance.  Returns a value between 1 (min. distance) and 14 (max. distance)
    def self.manhattan_distance(from, to)
      ((to.r - from.r).abs + (to.c - from.c).abs)
    end # distance between 1 and 14

    # Returns 1 (maximum bonus) at minimum distance, and 0 (no bonus) at max distance.
    def self.distance_ratio(from, to)
      distance = manhattan_distance(from, to)
      -distance/13.0 + 14.0/13.0
    end

    # Base bonuses are scaled so that total king tropism eval. component
    # is around 5% of total material value.
    BASE_BONUS_RATIO = 0.10
    BASE_BONUS = {  P: Pieces::PIECE_VALUES[:P]*BASE_BONUS_RATIO,  # 10.0
                    N: Pieces::PIECE_VALUES[:N]*BASE_BONUS_RATIO,  # 32.0
                    B: Pieces::PIECE_VALUES[:B]*BASE_BONUS_RATIO,  # 33.3
                    R: Pieces::PIECE_VALUES[:R]*BASE_BONUS_RATIO,  # 51.0
                    Q: Pieces::PIECE_VALUES[:Q]*BASE_BONUS_RATIO,  # 88.0
                    K: 0.0 } # 32.0

    # Each piece is awarded a bonus scaled based on how close it is to the enemy king.
    def self.create_bonus_table(from, to)
      ratio, hsh = distance_ratio(from, to), {}
      BASE_BONUS.each do |key, bonus|
        hsh[key] = (bonus*ratio).round.to_i
      end
      return hsh 
    end

    DIST = create_distance_table  # a 64 x 64 x 6 table 

    def self.get_bonus(piece, piece_loc, king_loc)
      DIST[piece_loc][king_loc][piece.class.type]
    end

  end
end





















