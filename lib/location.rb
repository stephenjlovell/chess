module Application
  module Location
    
    NUMBER_TO_LETTER = { 2 => "a", 3 => "b", 4 => "c", 5 => "d", 
                         6 => "e", 7 => "f", 8 => "g", 9 => "h" }
    LETTER_TO_NUMBER = { "a" => 2, "b" => 3, "c" => 4, "d" => 5,
                         "e" => 6, "f" => 7, "g" => 8, "h" => 9 }

    class Location
      attr_reader :r, :c
      
      def initialize(r,c)
        @r, @c = r,c
      end

      def eql?(other)
        @r.eql?(other.r) && @c.eql?(other.c)
      end

      alias :== :eql? 

      def +(arr)  
        self.class.new(@r+arr[0], @c+arr[1])
      end  # using get_location here would create a circular definition that would trip up 
           # the interpreter.

      # def +(arr)
      #   Application::Location::get_location(@r+arr[0], @c+arr[1])
      # end

      def hash
        to_a.hash
      end

      def copy
        self.class.new(@r, @c)
      end

      def to_s
        (NUMBER_TO_LETTER[@c]) + (@r - 1).to_s
      end

      def to_sym
        to_s.to_sym
      end

      def to_a
        [@r, @c]
      end
    end

    # module helper methods

    def self.create_locations
      hsh = {}
      (2..9).each do |r|
        hsh[r] = {}
        (2..9).each do |c|
          hsh[r][c] = Location.new(r, c)
        end
      end
      return hsh
    end

    LOCATIONS = create_locations

    # def self.all_locations
    #   @@all_locations ||= create_locations
    #   # @@all_locations
    # end

    def self.get_location(r, c)
      # puts "all_locations: #{all_locations}"
      # all_locations[r][c]
      LOCATIONS[r][c]
    end

    def self.get_location_from_string(str)
      get_location(str[1].to_i + 1, LETTER_TO_NUMBER[str[0]])
    end

    def self.inspect
      "<Application::Location <@@locations: #{@@locations}>>"
    end

  end
end




