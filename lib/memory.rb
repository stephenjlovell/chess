module Application
  module Memory

    class Entry # this class contains the information to be stored in each bucket.
      attr_reader :depth, :lower_bound, :upper_bound, :value
      # @type may be :upper_bound, :lower_bound, :exact_match
      def initialize(depth, lower_bound, upper_bound, value)
        @depth, @lower_bound, @upper_bound, @value = depth, lower_bound, upper_bound, value
      end
    end

    class TranspositionTable # this class generates a hash code for each explored position  
      # using a Zobrist hashing algorithm, and stores the value of each position.
      # A single instance of this class is contained in Application::Game instances.
      def initialize
        @table = {}
      end

      # def remembers?(node)
      #   h = hash(node)
      #   !!@table[h]
      # end

      def store(node, depth, lower_bound, upper_bound, value=nil)
        h = hash(node)
        value ||= node.value
        @table[h] = Entry.new(depth, lower_bound, upper_bound, value)
      end

      def retrieve(node)
        h = hash(node)
        @table[h]
      end

      def [](h)
        @table[h]
      end

      def memoize(node, depth, alpha, beta) 
        h = hash(node)
        node.hash_value = h # store h in position object instance variable to enable 
                                # incremental calculation of hashes for child nodes.
        unless @table[h]
          @table[h] = Entry.new(depth, alpha, beta, node.value)
        end
        return @table[h].value
      end

      def self.create_bytestring_array
        Array.new(8, Array.new(8, piece_hash ))
      end
      
      def self.piece_hash # creates a 12 element hash associating each piece to a 
        hsh = {}              # set of 16 random bytes packed in a string.
        [ :wP, :wN, :wB, :wR, :wQ, :wK, 
          :bP, :bN, :bB, :bR, :bQ, :bK ].each do |sym|
          hsh[sym] = SecureRandom::random_bytes
        end
        return hsh
      end

      BSTR = create_bytestring_array

      def hash(position)  # generates a unique hash key corresponding to position.
        key = 0
        # parent_hash = position.parent.hash_value || nil
        # if parent_hash
        #   # call method to create a 
        # else
        #   position.board.each_square_with_location do |r, c, sym|
        #     BSTR[r-2][c-2][sym].unpack('L*').each { |i| key ^= i } unless sym.nil? 
        #   end  # unpack to 64-bit unsigned long ints and merge into key via bitwise XOR.
        # end
        position.board.each_square_with_location do |r, c, sym|
          BSTR[r-2][c-2][sym].unpack('L*').each { |i| key ^= i } unless sym.nil? 
        end  # unpack to 64-bit unsigned long ints and merge into key via bitwise XOR.
        return key
      end
    end # end TranspostionTable class



  end
end




