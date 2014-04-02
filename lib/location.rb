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

module Chess
  module Location
  
    # Convert array coordinates to and from string representation:
    NUMBER_TO_LETTER = { 2 => "a", 3 => "b", 4 => "c",   5 => "d", 
                         6 => "e",  7 => "f",  8 => "g", 9 => "h" }  
    LETTER_TO_NUMBER = { "a" => 2, "b" => 3, "c" => 4, "d" => 5,
                         "e" => 6, "f" => 7, "g" => 8, "h" => 9 }

    SQUARES = { a1: 0,  b1: 1,  c1: 2,  d1: 3,  e1: 4,  f1: 5,  g1: 6,  h1: 7,
                a2: 8,  b2: 9,  c2: 10, d2: 11, e2: 12, f2: 13, g2: 14, h2: 15,
                a3: 16, b3: 17, c3: 18, d3: 19, e3: 20, f3: 21, g3: 22, h3: 23,
                a4: 24, b4: 25, c4: 26, d4: 27, e4: 28, f4: 29, g4: 30, h4: 31,
                a5: 32, b5: 33, c5: 34, d5: 35, e5: 36, f5: 37, g5: 38, h5: 39,
                a6: 40, b6: 41, c6: 42, d6: 43, e6: 44, f6: 45, g6: 46, h6: 47,
                a7: 48, b7: 49, c7: 50, d7: 51, e7: 52, f7: 53, g7: 54, h7: 55,
                a8: 56, b8: 57, c8: 58, d8: 59, e8: 60, f8: 61, g8: 62, h8: 63 }

    #  Location class instances are immutable and represent individual squares on the chessboard.
    #
    #  A 12 x 12 array of location objects (including locations for out-of-bounds coordinates) is created
    #  at startup. All usage of this class is by reference to these instances.  Location instances provide:
    #    1. Symbol and string representations of chess squares.
    #    2. Suitability for use as a hash key via its :hash and :eql? methods.  Used by position class
    #       to index piece lists by location of piece.  Hash value does not need to be recalculated,
    #       reducing overhead when inserting and removing pieces from piece lists.
    #    3. Simplified interface for vector addition through the :+ method. Displacement
    #       vectors are used for move generation, king saftey, and Static Exchange Evaluation.       

    class Location
      attr_reader :r, :c, :hash, :index
      
      def initialize(r,c)
        @r, @c = r, c
        @symbol = to_s.to_sym  # Since instances are immutable, :symbol and :hash values
        @hash = to_a.hash      # can be calculated once at object initialization.
        @index = SQUARES[@symbol]
        @bitcode = @index.nil? ? 0 : 2**(@index)
      end

      def eql?(other)
        @hash == other.hash
      end
      alias :== :eql? 

      def to_s  # Represent the location as a string, i.e. "a1"
        if NUMBER_TO_LETTER[@c]
          (NUMBER_TO_LETTER[@c]) + (@r - 1).to_s 
        else
          "XX_#{@r}_#{@c}"
        end
      end

      def to_b
        @bitcode
      end

      def to_sym
        @symbol
      end

      def to_a
        [@r, @c]
      end

      def self.include(sym, &proc)  # Public class method allowing new instance methods
        define_method(sym, &proc)   # to be dynamically added.  Used to add the :+ method
      end                           # during startup.
    end

    # Create a 12 x 12 array of location objects (including locations for out-of-bounds coordinates)
    def self.create_locations
      arr = Array.new(12) { Array.new(12) }
      arr.each_with_index { |row, r| row.each_with_index { |loc, c| row[c] = Location.new(r,c) } }
      arr
    end

    def self.valid_locations
      LOCATIONS[2..9].collect { |r| r[2..9] }.flatten
    end

    # set up location lookup access by symbol, index, and bitcode
    def self.setup_locations_access
      by_sym, by_index, by_bitcode = {}, {}, {}
      valid_locations.each do |loc|
        by_sym[loc.to_sym] = loc
        by_index[loc.index] = loc
        by_bitcode[loc.to_b] = loc
      end
      return by_sym, by_index, by_bitcode
    end


    LOCATIONS = create_locations

    # Create hashes for looking up valid locations by various properties.
    LOCATIONS_BY_SYM, LOCATIONS_BY_INDEX, LOCATIONS_BY_BITCODE = setup_locations_access

    LOCATIONS_BY_SYM.each do |sym, loc|
  end

    # :+ method is used for vector addition.  It accepts an increment vector as a 2-element
    # array and returns the Location object corresponding to the new row and column coordinates.
    
    Location.include(:+) do |arr|      # Append :+ method to Location class
      LOCATIONS[@r+arr[0]][@c+arr[1]]  # (hack to avoid a circular definition when 
    end                                # LOCATIONS array is created at startup).

    # Return the location object corresponding to the given coordinates.
    def self.get_location_by_coordinates(r, c)
      return nil if LOCATIONS[r].nil?
      LOCATIONS[r][c]
    end

    def self.get_location_by_symbol(sym)
      LOCATIONS_BY_SYM[sym]
    end

    def self.get_location_by_index(index)
      LOCATIONS_BY_INDEX[index]
    end

    def self.get_location_by_bitcode(bitcode)
      LOCATIONS_BY_BITCODE[bitcode]
    end

    # Return the location object corresponding to the given string (i.e. "a1").
    def self.string_to_location(str)
      location = get_location_by_coordinates(str[1].to_i + 1, LETTER_TO_NUMBER[str[0]])
      raise "invalid location for #{str}" if location.nil?
      location
    end

  end
end


# a1: (2, 2)
# b1: (2, 3)
# c1: (2, 4)
# d1: (2, 5)
# e1: (2, 6)
# f1: (2, 7)
# g1: (2, 8)
# h1: (2, 9)
# a2: (3, 2)
# b2: (3, 3)
# c2: (3, 4)
# d2: (3, 5)
# e2: (3, 6)
# f2: (3, 7)
# g2: (3, 8)
# h2: (3, 9)
# a3: (4, 2)
# b3: (4, 3)
# c3: (4, 4)
# d3: (4, 5)
# e3: (4, 6)
# f3: (4, 7)
# g3: (4, 8)
# h3: (4, 9)
# a4: (5, 2)
# b4: (5, 3)
# c4: (5, 4)
# d4: (5, 5)
# e4: (5, 6)
# f4: (5, 7)
# g4: (5, 8)
# h4: (5, 9)
# a5: (6, 2)
# b5: (6, 3)
# c5: (6, 4)
# d5: (6, 5)
# e5: (6, 6)
# f5: (6, 7)
# g5: (6, 8)
# h5: (6, 9)
# a6: (7, 2)
# b6: (7, 3)
# c6: (7, 4)
# d6: (7, 5)
# e6: (7, 6)
# f6: (7, 7)
# g6: (7, 8)
# h6: (7, 9)
# a7: (8, 2)
# b7: (8, 3)
# c7: (8, 4)
# d7: (8, 5)
# e7: (8, 6)
# f7: (8, 7)
# g7: (8, 8)
# h7: (8, 9)
# a8: (9, 2)
# b8: (9, 3)
# c8: (9, 4)
# d8: (9, 5)
# e8: (9, 6)
# f8: (9, 7)
# g8: (9, 8)
# h8: (9, 9)

