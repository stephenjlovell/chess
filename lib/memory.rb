module Chess
  module Memory
    require 'SecureRandom'

    #  The TranspositionTable (TT) class handles storage and retrieval of results for previous subtree searches.
    #  This allows the re-use of information gained in previous searches, and avoids wasteful re-expansion of the same
    #  subtree. Design considerations:
    #
    #    1. Replacement Scheme - The size of each subtree is collected in the Search stack. When 
    #       search results are stored, if the TT already contains results for that node, the result that
    #       was based on the largest subtree will be saved, and the smaller (and presumably less accurate)
    #       search result is discarded.
    #     
    #    2. Storage - Each saved result is stored in a TTBoundEntry instance.  Rather than saving the value and a
    #       flag indicating node type, each entry saves both lower and upper bounds on the search.  These bounds
    #       can be used to adjust local bounds, and are required for some MTD(f) based search algorithms to perform well.
    #
    #    3. Hashing - 64-bit hash keys for nodes are computed via Zobrist hashing (see below).  Hash keys are incrementally
    #       updated during move generation.

    TTBoundEntry = Struct.new(:key, :lower, :upper, :move)

    TTBoundSlot = Struct.new(:depth, :count, :bound)

    class TranspositionTable
      def initialize
        @table = {}
      end

      def clear
        @table = {}
      end

      def length
        @table.length
      end
      alias :size :length
      alias :count :length

      def ok?(node)
        key_ok?(node.hash) 
      end

      # Compare the full key to the key saved in the TT entry to avoid possible type 2 (indexing) hash collisions.
      def key_ok?(h)
        @table.has_key?(h) && @table[h].key == h
      end

      def get(node)
        @table[node.hash]
      end

      def [](h)
        @table[h]
      end

      # Probe the TT for saved search results.  If a valid entry is found, push the stored best move into
      # first_moves array. If stored result would cause cutoff of local search, return the stored result.
      def probe(node, depth, alpha, beta)
        if ok?(node)
          $memory_calls += 1
          e = get(node)
          lower, upper = e.lower, e.upper

          move = !e.move.nil? && node.avoids_check?(e.move) ? e.move : nil

          lower_ok = lower.depth >= depth
          if lower_ok && lower.bound >= beta
            return move, lower.bound, lower.count
          end
          upper_ok = upper.depth >= depth
          if upper_ok && upper.bound <= alpha
            return move, upper.bound, upper.count
          end
          if lower_ok && upper_ok && alpha < lower.bound && upper.bound < beta
            # Return scores for exact entries. Exact entries will not occur during zero-width 
            # ('minimal window') searches.
            return move, upper.bound, upper.count  # return an 'exact' score
          end
          return move, nil, nil
        end
        return nil, nil, nil  # sentinel indicating stored bounds were not sufficient to cause immediate cutoff.
      end

      # Special probing method for use with Enhanced Transposition Cutoffs (ETC).  Used to probe for child positions
      # found via a make/unmake of each move.
      def etc_probe(node, depth, alpha, beta, is_max)
        if ok?(node)
          $memory_calls += 1
          e = get(node)
          lower, upper = e.lower, e.upper
          lower_ok, upper_ok = lower.depth >= depth, upper.depth >= depth

          if is_max
            if lower_ok && lower.bound >= beta
              return lower.bound, lower.count
            end
          else
            if upper_ok && upper.bound <= alpha
              return upper.bound, upper.count
            end
          end
          if lower_ok && upper_ok && alpha < lower.bound && upper.bound < beta
            return upper.bound, upper.count  # return an 'exact' score
          end
        end
        return nil, nil  # sentinel indicating stored bounds were not sufficient to cause an immediate cutoff.
      end

      # Special probing method for use with Enhanced Transposition Cutoffs (ETC).  Used to probe for child positions
      # without doing a full make/unmake cycle.
      def etc_key_probe(key, depth, alpha, beta, is_max)
        if key_ok?(key)
          $memory_calls += 1
          e = @table[key]
          lower, upper = e.lower, e.upper
          lower_ok, upper_ok = lower.depth >= depth, upper.depth >= depth

          if is_max
            if lower_ok && lower.bound >= beta
              return lower.bound, lower.count
            end
          else
            if upper_ok && upper.bound <= alpha
              return upper.bound, upper.count
            end
          end
          if lower_ok && upper_ok && alpha < lower.bound && upper.bound < beta
            return upper.bound, upper.count  # return an 'exact' score
          end
        end
        return nil, nil
      end

      # If an entry is available for node, return the best move stored from the previous search.
      def get_hash_move(node)
        if ok?(node)
          e = get(node)  # if hash move is illegal, don't use it:
          return e.move unless e.move.nil? || !node.avoids_check?(e.move)
        end
        nil
      end

      # Store search results for node. Only overwrite existing entry if new information is based on search
      # of a larger subtree than the existing entry.
      def store(node, depth, count, result, alpha, beta, move)
        h = node.hash
        if @table.has_key?(h)
          e = @table[h]
          lower, upper = e.lower, e.upper
          lower_ok, upper_ok = count >= lower.count, count >= upper.count
          
          if lower_ok
            e.move = move
            if result <= alpha
              upper.depth, upper.count, upper.bound = depth, count, result
            else
              upper.depth, upper.count, upper.bound = depth, count, beta
            end
          end
          if upper_ok
            e.move = move
            if result >= beta
              lower.depth, lower.count, lower.bound = depth, count, result
            else
              lower.depth, lower.count, lower.bound = depth, count, alpha
            end
          end
          if lower_ok && upper_ok
            e.move = move
            if alpha < result && result < beta
              upper.depth, upper.count, upper.bound = depth, count, result
              lower.depth, lower.count, lower.bound = depth, count, result
            end
          end
        else 
          a, b = alpha, beta
          fail_low, fail_high = result <= alpha, result >= beta
          b = result if fail_low
          a = result if fail_high      
          if !fail_low && !fail_high
            a, b = result, result 
          end
          @table[h] = TTBoundEntry.new(h, TTBoundSlot.new(depth, count, a), TTBoundSlot.new(depth, count, b), move)
        end
        return result, count
      end

    end # end TranspostionTable class

    # When using 64-bit hash keys, Type I (hash collision) errors are extremely rare (once in 10,000+ searches 
    # at depth 6), but could theoretically still happen. These are particularly difficult to detect and can corrupt the
    # position / board representation when moves are made that are invalid for the current position.  If an error occurs
    # resulting from corruption of the internal board state, a HashCollisionError is raised.

    class HashCollisionError < StandardError 
    end


    # Zobrist Hashing
    #
    # These module helper methods implement Zobrist Hashing.  Each possible square and piece combination
    # is assigned a unique 64-bit integer key at startup.  A hash key for a given chess position can then be
    # generated by merging (via XOR) the keys for each piece/square combination, and merging in keys representing
    # the side to move, castling rights, and any en-passant target square.

    # Create a 10 x 10 array containing the results of the block passed to create_key_array.
    # The block should return either a random integer key, or a data structure containing random integer keys.
    def self.create_key_array
      Array.new(10) { Array.new(10) { yield } } 
    end
    
    # Create a 12 element hash associating each piece symbol to a random 64-bit integer.
    def self.piece_hash 
      hsh = {}          
      [:wP, :wN, :wB, :wR, :wQ, :wK, :bP, :bN, :bB, :bR, :bQ, :bK].each do |sym| 
        hsh[sym] = create_key
      end
      return hsh
    end

    def self.create_key  # Return a random 64-bit integer.
      SecureRandom::random_number(2**64)
    end

    # Create a 10 x 10 x 12 structure associating each possible square and piece combination 
    # with its own random 64-bit key.
    PSQ = create_key_array { piece_hash } 

    # Create a 10 x 10 array associating possible en-passant target squares with their own 
    # random 64-bit integer key.
    ENP = create_key_array { create_key }

    SIDE = 1  # Integer key representing a change in side-to-move.  Used during make/unmake to update 
              # hash key of node.

    # Return the Zobrist key for the given en-passant target.
    def self.enp_key(enp_target)
      return 0 if enp_target.nil?
      ENP[enp_target.r][enp_target.c]
    end

    # Return the Zobrist key corresponding to the given piece and location.
    def self.psq_key(piece, location)
      PSQ[location.r][location.c][piece.symbol]
    end

    # Return the Zobrist key corresponding to the given piece and square coordinates.
    def self.psq_key_by_square(r, c, sym)  # Alternative method for use with board object. 
      PSQ[r][c][sym]
    end

  end
end




