module Application
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
    SIDE = create_key

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
      attr_reader :depth, :type, :value, :best_move
      # @type may be :upper_bound, :lower_bound, :exact_match
      def initialize(depth, type, value, best_move)
        @depth, @type, @value, @best_move = depth, type, value, best_move
      end
    end

    class TranspositionTable # this class generates a hash code for each explored position  
      # using a Zobrist hashing algorithm, and stores the value of each position.
      # A single instance of this class is contained in Application::Game instances.
      def initialize
        @table = {}
      end

      # will need to refactor this 

      def store_result(max_depth, mate_possible, node, depth, best_value, alpha, beta, best_move=nil)
        if mate_possible && node.in_check?
          store_checkmate(node, max_depth)
        else
          store_node(node, depth, best_value, alpha, beta, best_move)
        end
      end
  
      def store_node(node, depth, best_value, alpha, beta, best_move=nil)
        flag = if best_value <= alpha
          :lower_bound
        elsif best_value >= beta
          :upper_bound
        else
          :exact_value
        end
        store_entry(node, depth, flag, best_value, best_move)
      end

      def store_checkmate(node, max_depth)
        store_entry(node, max_depth+1, :exact_value, -$INF)
      end

      def store_entry(node, depth, type, value, best_move=nil)
        h = node.hash
        if @table[h].nil? || depth >= @table[h].depth   # simple depth-based replacement scheme.
          @table[h] = Entry.new(depth, type, value, best_move)
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




