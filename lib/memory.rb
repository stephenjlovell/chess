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

    class PVStack
      include Enumerable
      attr_accessor :moves

      def initialize(moves=[])
        @moves = moves
        @counter = 0
      end

      def each
        @moves.each { |m| yield(m) }
      end

      def +(stack)
        @moves += stack.moves
        return self
      end

      def clear
        @moves = []
      end

      def next_move
        move = @moves[@counter]
        @counter += 1
        return move
      end

      def reset_counter
        @counter = 0
      end

      def [](index)
        @moves[index]
      end

      def []=(index, move)
        @moves[index] = move
      end

      def print
        puts "\n------Principal Variation (#{self.count} moves)------"
        each { |m| puts m.print }
        puts "\n"
      end
    
      def print_details
        puts "------Principal Variation (#{self.count} moves)------"
        each do |m|
          puts m.position.board.print
          puts m.print
        end
      end
    end


    class Entry # this class contains the information to be stored in each bucket.
      attr_reader :depth, :type, :value, :best_move
      # @type may be :upper_bound, :lower_bound, :exact_match
      def initialize(depth, type, value, best_move)
        @depth, @type, @value, @best_move = depth, type, value, best_move
      end
    end

    class TranspositionTable # this class generates a hash code for each explored position  
      # using a Zobrist hashing algorithm, and stores the value of each position.
      # A single instance of this class is contained in Chess::Game instances.
      
      def initialize
        # due to potentially large size and high throughput of hash table 
        # (100k - 1m keys), Ruby core Hash is too inefficient.  Use Google dense_hash_map instead.
        # http://incise.org/hash-table-benchmarks.html
        @table = GoogleHashDenseLongToRuby.new
      end

      def probe(node, depth, alpha, beta, first_moves=nil)
        if contains?(node)
          $memory_calls += 1
          entry = retrieve(node)
          if entry.depth >= depth # if entry was searched to greater than current depth, use instead of searching.
            return entry.value if entry.type == :exact_value
            return alpha if entry.type == :lower_bound && entry.value <= alpha
            return beta if entry.type == :upper_bound && entry.value >= beta
          end
          first_moves << entry.best_move if first_moves && !entry.best_move.nil?
        end
        return nil  # sentinel indicating probe was unsuccessful in creating an immediate search cutoff.
      end
  
      def flag_and_store(node, depth, best_value, alpha, beta, best_move=nil)
        flag = if best_value <= alpha
          :lower_bound
        elsif best_value >= beta
          :upper_bound
        else
          :exact_value
        end
        store(node, depth, flag, best_value, best_move)
      end

      def store(node, depth, type, value, best_move=nil)
        h = node.hash
        if !@table.has_key?(h) || depth >= @table[h].depth   # simple depth-based replacement scheme.
          @table[h] = Entry.new(depth, type, value, best_move)
        end
        return @table[h].value
      end

      def length
        @table.length
      end
      alias :size :length
      alias :count :length

      def contains?(node)
        @table.has_key?(node.hash)
      end

      def retrieve(node)
        @table[node.hash]
      end

      def clear
        @table = GoogleHashDenseLongToRuby.new
      end

    end # end TranspostionTable class

  end
end




