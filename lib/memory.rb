module Chess
  module Memory
    require 'SecureRandom'

    TTBoundEntry = Struct.new(:key, :depth, :count, :alpha, :beta, :move)

    class TranspositionTable # This class stores bounds on the heuristic value of the largest subtree
      # explored so far for each position encountered.
      
      def initialize
        # due to potentially large size and high throughput of hash table 
        # (100k - 1m keys), Ruby core Hash is too inefficient.  Use Google dense_hash_map instead.
        # http://incise.org/hash-table-benchmarks.html
        # @table = GoogleHashDenseLongToRuby.new
        @table = {}
      end

      def length
        @table.length
      end
      alias :size :length
      alias :count :length

      def clear
        # @table = GoogleHashDenseLongToRuby.new
        @table = {}
      end

      def contains?(node)
        @table.has_key?(node.hash)
      end

      def ok?(node)
        h = node.hash # compare the full key to avoid type 2 (index) hash collisions:
        @table.has_key?(h) && @table[h].key == h
      end

      def key_ok?(h)
        @table.has_key?(h) && @table[h].key == h
      end

      def get(node)
        @table[node.hash]
      end

      def [](h)
        @table[h]
      end

      def probe(node, alpha, beta)
        if $tt.ok?(@node)  # probe the hash table for @node
          $memory_calls += 1
          e = $tt.get(@node)
          unless e.nil?
            first_moves << e.move unless e.move.nil?
            if e.depth >= depth
              return e.alpha, e.count if e.alpha >= beta
              return e.beta, e.count if e.beta <= alpha
              # alpha = Chess::max(alpha, e.alpha)   # Using TT to adjust local bounds reduces branching factor, but also
              # beta = Chess::min(beta, e.beta)      # creates search instability that can decrease playing strength.
            end
          end
        end
      end

      def get_hash_move(node, first_moves)
        if ok?(node)
          e = get(node)  # if hash move is illegal, don't use it:
          first_moves << e.move unless e.move.nil? || !node.avoids_check?(e.move)
        end
      end

      def store_result(node, depth, count, result, alpha, beta, move)
        h = node.hash
        if !@table.has_key?(h)
          alpha, beta = set_bounds(result, alpha, beta)
          @table[h] = TTBoundEntry.new(h, depth, count, alpha, beta, move)
        elsif count >= @table[h].count
        # elsif depth >= @table[h].depth
          e = @table[h] 
          alpha, beta = set_bounds(result, alpha, beta)
          e.depth, e.count, e.alpha, e.beta, e.move = depth, count, alpha, beta, move
        end
        return result, count
      end

      private

      def set_bounds(result, alpha, beta)
        a, b = alpha, beta
        b = result if result <= alpha
        if alpha < result && result < beta
          a, b = result, result
        end 
        a = result if result >= beta
        return a, b                       
      end
    end # end TranspostionTable class

    def self.create_key_array
      arr = Array.new(10) { Array.new(10) }
      (2..9).each { |r| (2..9).each { |c| arr[r][c] = yield() } }
      return arr
    end
    
    def self.piece_hash # creates a   12 element hash associating each piece to a 
      hsh = {}          # random 64 bit unsigned long integer.
      [:wP, :wN, :wB, :wR, :wQ, :wK, :bP, :bN, :bB, :bR, :bQ, :bK].each do |sym| 
        hsh[sym] = create_key
      end
      return hsh
    end

    def self.create_key
      SecureRandom::random_number(2**64)
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

  end
end




