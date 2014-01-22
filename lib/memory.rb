module Application
  module Memory
    require 'SecureRandom'
    
    def self.piece_hash # creates a 12 element hash associating each piece to a 
      hsh = {}          # random 64 bit unsigned long integer.
      [:wP, :wN, :wB, :wR, :wQ, :wK, :bP, :bN, :bB, :bR, :bQ, :bK].each do |sym| 
        hsh[sym] = SecureRandom::random_bytes.unpack('L*').inject(0) { |key, i| key ^= i }
      end
      return hsh
    end

    BSTR = Array.new(10) { Array.new(10) { piece_hash } } # only the last 8x8 will be used.

    def self.get_key(piece, location)
      BSTR[location.r][location.c][piece.symbol]
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
        puts "------Principal Variation (#{self.count} moves)------"
        each { |m| puts m.to_s }
      end
    
      def print_details
        puts "------Principal Variation (#{self.count} moves)------"
        each do |m|
          puts m.position.board.print
          puts m.to_s
        end
      end
    end


    class Entry # this class contains the information to be stored in each bucket.
      attr_reader :depth, :type, :value, :best_node
      # @type may be :upper_bound, :lower_bound, :exact_match
      def initialize(depth, type, value, best_node)
        @depth, @type, @value, @best_node = depth, type, value, best_node
      end
    end

    class TranspositionTable # this class generates a hash code for each explored position  
      # using a Zobrist hashing algorithm, and stores the value of each position.
      # A single instance of this class is contained in Application::Game instances.
      def initialize
        @table = {}
      end

      def store_result(root, max_depth, mate_possible, node, depth, best_value, alpha, beta, best_node=nil)
        if mate_possible && node.in_check?
          store_checkmate(root, max_depth, node)
        else
          store_node(node, depth, best_value, alpha, beta, best_node)
        end
      end
  
      def store_node(node, depth, best_value, alpha, beta, best_node=nil)
        flag = if best_value <= alpha
          :lower_bound
        elsif best_value >= beta
          :upper_bound
        else
          :exact_value
        end
        store_entry(node, depth, flag, best_value, best_node)
      end

      def store_checkmate(root, max_depth, node)
        value = root.side_to_move == node.side_to_move ? -$INF : $INF
        store_entry(node, max_depth+1, :exact_value, value)
      end

      def store_entry(node, depth, type, value, best_node=nil)
        h = node.hash
        if @table[h].nil? || depth >= @table[h].depth   # simple depth-based replacement scheme.
          @table[h] = Entry.new(depth, type, value, best_node)
        end
        return @table[h].value
      end

      def retrieve(node)
        h = node.hash
        $memory_calls += 1 if @table[h]
        @table[h]
      end

    end # end TranspostionTable class

  end
end




