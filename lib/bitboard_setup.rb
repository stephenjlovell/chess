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

require './lib/bitboard.rb'

module Chess
  module Bitboard

    KNIGHT_OFFSETS = [ -17, -15, -10, -6, 6, 10, 15, 17 ]
    BISHOP_OFFSETS = [ -9, -7, 7, 9 ]
    ROOK_OFFSETS   = [ -8, -1, 1, 8 ]
    KING_OFFSETS   = [ -9, -7, 7, 9, -8, -1, 1, 8 ]
    PAWN_OFFSETS = { w: [9, 7], b: [-9, -7] }

    def self.empty_bb_array
      Array.new(64, 0)
    end

    # Create an array of 64 bitboards showing the knight moves possible from each
    # square (assuming an otherwise blank board).
    def self.setup_knight_masks
      64.times.map do |from|
        KNIGHT_OFFSETS.inject(0) do |b, offset|
          to = from + offset     # bitboard via bitwise OR.
          if to >= 0 && to <= 63 && manhattan_distance(from, to) == 3
            b |= (1<<to)
          end
          b
        end
      end
    end

    # Create an array of 64 bitboards showing the king moves possible from each
    # square (assuming an otherwise blank board).
    def self.setup_king_masks
      64.times.map do |from|
        KING_OFFSETS.inject(0) do |b, offset|
          to = from + offset     # bitboard via bitwise OR.
          if to >= 0 && to <= 63 && manhattan_distance(from, to) <= 2
            b |= (1<<to)
          end
          b
        end
      end
    end

    # Create arrays of 64 bitboards showing the bishop moves possible from each
    # square (assuming an otherwise blank board), and separate bitboard arrays for each direction.
    def self.setup_bishop_masks
      nw, ne, sw, se = empty_bb_array, empty_bb_array, empty_bb_array, empty_bb_array
      64.times do |from|
        BISHOP_OFFSETS.each do |offset|
          previous, current = from, from + offset
          # Make sure the search doesn't wrap around the end of a row or go off the 8x8 board.
          while current >= 0 && current <= 63 && manhattan_distance(current, previous) == 2               
            square_key = 1 << current
            if offset == 7
              nw[from] |= square_key 
            elsif offset == 9
              ne[from] |= square_key
            elsif offset == -7
              sw[from] |= square_key
            else
              se[from] |= square_key
            end
            previous = current
            current += offset
          end
        end
      end
      return nw, ne, sw, se
    end

    # Create arrays of 64 bitboards showing the rook moves possible from each
    # square (assuming an otherwise blank board).
    def self.setup_rook_masks
      south, west, east, north, all = empty_bb_array, empty_bb_array, empty_bb_array, empty_bb_array
      64.times do |from|
        ROOK_OFFSETS.each do |offset|
          previous, current = from, from + offset
          # # Make sure the search doesn't wrap around the end of a row or go off the 8x8 board.
          while current >= 0 && current <= 63 && manhattan_distance(current, previous) == 1
            square_key = 1 << current
            if offset == -8
              south[from] |= square_key 
            elsif offset == -1
              west[from] |= square_key
            elsif offset == 8
              north[from] |= square_key
            else
              east[from] |= square_key
            end
            previous = current
            current += offset
          end
        end
      end 
      return south, west, east, north
    end

    def self.setup_pawn_masks
      hsh = { w: empty_bb_array, b: empty_bb_array }
      64.times do |from|
        if from < 56
          PAWN_OFFSETS[:w].each do |offset|
            to = from + offset
            hsh[:w][from] |= (1<<to) if manhattan_distance(from, to) == 2
          end
        end
        if from > 7
          PAWN_OFFSETS[:b].each do |offset|
            to = from + offset
            hsh[:b][from] |= (1<<to) if manhattan_distance(from, to) == 2
          end
        end
      end
      return hsh
    end

    def self.setup_masks
      hsh = {}
      hsh[:N] = setup_knight_masks
      hsh[:P] = setup_pawn_masks
      hsh[:K] = setup_king_masks
      hsh[:NW], hsh[:NE], hsh[:SW], hsh[:SE] = setup_bishop_masks
      hsh[:SO], hsh[:WE], hsh[:EA], hsh[:NO] = setup_rook_masks
      hsh[:B] = 64.times.map { |i| hsh[:NW][i]|hsh[:NE][i]|hsh[:SW][i]|hsh[:SE][i] }
      hsh[:R] = 64.times.map { |i| hsh[:SO][i]|hsh[:WE][i]|hsh[:EA][i]|hsh[:NO][i] }
      hsh[:Q] = 64.times.map { |i| hsh[:B][i]|hsh[:R][i] }
      return hsh
    end

    # Calculate bitboard attack maps ('masks') showing where the piece type can move to from each square.
    MASKS = setup_masks
    # MASKS[:K].each_with_index { |board, i| puts i; print_bitboard(board, i) }







  end
end

















