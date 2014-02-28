module Chess
  module Memory
    require 'SecureRandom'

    def self.create_key_array
      arr = Array.new(10) { Array.new(10) }
      (2..9).each { |r| (2..9).each { |c| arr[r][c] = yield() } }
      return arr
    end
    
    def self.piece_hash # creates a 12 element hash associating each piece to a 
      hsh = {}          # random 64 bit unsigned long integer.
      [:wP, :wN, :wB, :wR, :wQ, :wK, :bP, :bN, :bB, :bR, :bQ, :bK].each do |sym| 
        hsh[sym] = create_key
      end
      return hsh
    end

    def self.create_key
      SecureRandom::random_bytes.unpack('L*').inject(0) { |key, i| key ^= i }
    end

    PSQ = create_key_array { piece_hash }
    ENP = create_key_array { create_key }
    SIDE = 1

    def self.side_key
      SIDE
    end

    def self.enp_key(location)
      return 0 if location.nil?
      ENP[location.r][location.c]
    end

    def self.psq_key(piece, location)
      PSQ[location.r][location.c][piece.symbol]
    end

    def self.psq_key_by_square(r, c, sym)  # alternative method for use with board object. 
      PSQ[r][c][sym]
    end

    TTEntry = Struct.new(:depth, :type, :value, :move)

    TTBoundEntry = Struct.new(:depth, :alpha, :beta, :move)

    class TranspositionTable # this class generates a hash code for each explored position  
      # using a Zobrist hashing algorithm, and stores the value of each position.
      # A single instance of this class is contained in Chess::Game instances.
      
      def initialize
        # due to potentially large size and high throughput of hash table 
        # (100k - 1m keys), Ruby core Hash is too inefficient.  Use Google dense_hash_map instead.
        # http://incise.org/hash-table-benchmarks.html
        @table = GoogleHashDenseLongToRuby.new
      end

      def length
        @table.length
      end
      alias :size :length
      alias :count :length

      def clear
        @table = GoogleHashDenseLongToRuby.new
      end

      def contains?(node)
        @table.has_key?(node.hash)
      end

      def get(node)
        @table[node.hash]
      end

      def get_hash_move(node, first_moves)
        if contains?(node)
          # $memory_calls += 1
          entry = get(node)
          first_moves << entry.move unless entry.move.nil?
        end
      end

      def store_result(node, depth, result, alpha, beta, move)
        h = node.hash
        if !contains?(node)
          alpha, beta = set_bounds(result, alpha, beta)
          @table[h] = TTBoundEntry.new(depth, alpha, beta, move)
        elsif depth >= @table[h].depth
          e = @table[h]
          alpha, beta = set_bounds(result, alpha, beta)
          e.depth, e.alpha, e.beta, e.move = depth, alpha, beta, move
        end
        result
      end

      private

      def set_bounds(result, alpha, beta)
        a, b = alpha, beta
        b = result if result < beta     
        a = result if result > alpha     
        # if alpha <= result && result <= beta         
        #   a, b = result, result           # accurate value found   
        # end
        return a, b
      end
    end # end TranspostionTable class

  end
end




