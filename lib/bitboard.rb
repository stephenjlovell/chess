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

    def self.get_row(sq)  # rank
      sq >> 3
    end

    def self.get_column(sq)  # file
      sq & 7
    end


    # get the integer value of the least significant bit for integer x
    def self.lsb_value(x)
      x&-x
    end

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


    # example magic constant. One magic constant would be pre-computed for each square.
    MAGIC_CONSTANT = 0x07EDD5E59A4E28C2

    def self.magic_index(key, magic, index_size)
      (key*magic)>>(64-index_size)
    end

    # For each square, calculate a bitboard attack map ('mask') showing where the piece type can move to.
    # Each mask covers 7-14 squares for bishops, and exactly 14 squares for rooks.  When intersected with
    # a square occupancy map, a maximum of 128-16,384 combinations can occur per square.





    def self.create_magic_db(magic, index_size)
      bit = 1
      db = {}
      64.times do |i|
        db[magic_index(bit, magic, index_size)] = i
        bit <<= 1
      end
      return db
    end


    # 64 x 64 array for storing precomputed move bitboards.
    # MOVE_DB = create_move_db

    # 6 x 64 array of bitboards showing where each square can be attacked from for each color and piece type (given a blank board)
    
    MAGIC_DB = {}

    # MAGIC_DB = create_magic_db(MAGIC_CONSTANT, 6) #magic_bishop
    MASK_DB = {}   # magic_bishop_mask
    SHIFT_DB = {}  # magic_bishop_shift
    INDEX_DB = {}  # magic_bishop_indices


    # notional example. get moves for a sliding piece
    def self.get_bishop_moves(piece, square, occupancy)
      BISHOP_INDEX[square] + (((occupancy&MASK_DB[square])*MAGIC_DB[square])>>SHIFT_DB[square])
    end


  end
end








