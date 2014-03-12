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
      attr_reader :r, :c, :hash  
      
      def initialize(r,c)
        @r, @c = r, c
        @symbol = to_s.to_sym # Since instances are immutable, :symbol and :hash values
        @hash = to_a.hash     # can be calculated once at object initialization.
      end

      def eql?(other)
        @r.eql?(other.r) && @c.eql?(other.c)
      end
      alias :== :eql? 

      def to_s  # Represent the location as a string, i.e. "a1"
        if NUMBER_TO_LETTER[@c]
          (NUMBER_TO_LETTER[@c]) + (@r - 1).to_s 
        else
          "XX_#{@r}_#{@c}"
        end
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

    LOCATIONS = create_locations

    # :+ method is used for vector addition.  It accepts an increment vector as a 2-element
    # array and returns the Location object corresponding to the new row and column coordinates.
    
    Location.include(:+) do |arr|      # Append :+ method to Location class
      LOCATIONS[@r+arr[0]][@c+arr[1]]  # (hack to avoid a circular definition when 
    end                                # LOCATIONS array is created at startup).

    # Return the location object corresponding to the given coordinates.
    def self.get_location(r, c)
      return nil unless LOCATIONS[r]
      LOCATIONS[r][c]
    end

    # Return the location object corresponding to the given string (i.e. "a1").
    def self.string_to_location(str)
      location = get_location(str[1].to_i + 1, LETTER_TO_NUMBER[str[0]])
      raise "invalid location for #{str}" if location.nil?
      location
    end

  end
end




