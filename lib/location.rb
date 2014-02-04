module Application
  module Location
    
    NUMBER_TO_LETTER = { 0 => "XX", 1 => "XX", 2 => "a", 3 => "b", 4 => "c",   5 => "d", 
                         6 => "e",  7 => "f",  8 => "g", 9 => "h", 10 => "XX", 11 => "XX" }
    LETTER_TO_NUMBER = { "a" => 2, "b" => 3, "c" => 4, "d" => 5,
                         "e" => 6, "f" => 7, "g" => 8, "h" => 9 }

    class Location  # Immutable class. An array of location objects are created at
      attr_reader :r, :c, :hash  # startup and passed around by reference.

      class << self
        def include(sym, &proc)
          define_method(sym, &proc)
        end
      end
      
      def initialize(r,c)
        @r, @c = r, c
        @symbol = to_s.to_sym
        @hash = to_a.hash
      end

      def eql?(other)
        @r.eql?(other.r) && @c.eql?(other.c)
      end
      alias :== :eql? 

      def to_s
        (NUMBER_TO_LETTER[@c]) + (@r - 1).to_s
      end

      def to_sym
        @symbol
      end

      def to_a
        [@r, @c]
      end
    end

    def self.create_locations
      arr = Array.new(12) { Array.new(12) }
      arr.each_with_index { |row, r| row.each_with_index { |loc, c| row[c] = Location.new(r,c) } }
      return arr
    end

    LOCATIONS = create_locations
    Location.include(:+) do |arr|  # Append + method to Location class.
      LOCATIONS[@r+arr[0]][@c+arr[1]]  # Hack to avoid a circular definition when LOCATIONS
    end                                # constant is created at startup.

    def self.get_location(r, c)
      LOCATIONS[r][c]
    end

    def self.get_location_from_string(str)
      get_location(str[1].to_i + 1, LETTER_TO_NUMBER[str[0]])
    end

  end
end




