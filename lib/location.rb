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

    SQUARE_SYMS = [ :a1, :b1, :c1, :d1, :e1, :f1, :g1, :h1, 
                    :a2, :b2, :c2, :d2, :e2, :f2, :g2, :h2, 
                    :a3, :b3, :c3, :d3, :e3, :f3, :g3, :h3, 
                    :a4, :b4, :c4, :d4, :e4, :f4, :g4, :h4, 
                    :a5, :b5, :c5, :d5, :e5, :f5, :g5, :h5, 
                    :a6, :b6, :c6, :d6, :e6, :f6, :g6, :h6, 
                    :a7, :b7, :c7, :d7, :e7, :f7, :g7, :h7, 
                    :a8, :b8, :c8, :d8, :e8, :f8, :g8, :h8 ]

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

    def self.sq_to_s(sq)
      SQUARE_SYMS[sq].to_s
    end


    class InvalidLocationError
    end

    class Location
      attr_reader :hash, :index, :mask_on, :mask_off
      
      def initialize(square)
        @index = square
        @symbol = SQUARE_SYMS[square]
        @mask_on = (1<<square)
        @mask_off = (~@mask_on)
      end


      def eql?(other)
        @hash == other.hash
      end
      alias :== :eql? 

      def to_s  # Represent the location as a string, i.e. "a1"
        @symbol.to_s
      end

      def to_b
        @mask_on
      end

      def to_sym
        @symbol
      end
      alias :symbol :to_sym

      def hash
        @index
      end

    end

    LOCATIONS = 64.times.map {|sq| Location.new(sq) }


    # def self.get_location_by_symbol(sym)
    #   LOCATIONS[SQUARES[sym]]
    # end

    # def self.get_location(square)
    #   LOCATIONS[square]
    # end

    # def self.get_location_by_mask(mask)
    #   LOCATIONS[Bitboard::lsb(mask)-1]
    # end

    # # Return the location object corresponding to the given string (i.e. "a1").
    # def self.string_to_location(str)
    #   location = LOCATIONS[SQUARES[str.to_sym]]
    #   if location.nil?
    #     raise Notation::NotationFormatError, "No valid Chess::Location::Location object for string '#{str}'"
    #   end
    # end

  end
end



