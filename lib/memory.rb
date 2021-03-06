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

require './lib/location.rb'
require 'SecureRandom'
require './lib/pieces.rb'

module Chess
  module Memory
    #  The TranspositionTable (TT) class handles storage and retrieval of results for previous subtree searches.
    #  This allows the re-use of information gained in previous searches, and avoids wasteful re-expansion of the same
    #  subtree. Design considerations:
    #
    #    1. Replacement Scheme - The size of each subtree is collected in the Search stack. When 
    #       search results are stored, if the TT already contains results for that node, the result that
    #       was based on the largest subtree will be saved, and the smaller (and presumably less accurate)
    #       search result is discarded.
    #     
    #    2. Storage - Each saved result is stored in a TTEntry instance.  Rather than saving the value and a
    #       flag indicating node type, each entry saves both lower and upper bounds on the search.  These bounds
    #       can be used to adjust local bounds, and are required for some MTD(f) based search algorithms to perform well.
    #
    #    3. Hashing - 64-bit hash keys for nodes are computed via Zobrist hashing (see below).  Hash keys are incrementally
    #       updated during move generation.

    TTEntry = Struct.new(:key, :lower, :upper, :move)
    TTBound = Struct.new(:depth, :count, :bound)

    class TranspositionTable
      def initialize
        @table = {}
      end

      def clear
        @table.clear
      end

      def length
        @table.length
      end
      alias :size :length
      alias :count :length

      # Compare the full key to the key saved in the TT entry to avoid possible type 2 (indexing) hash collisions.
      def key_ok?(h)
        @table.has_key?(h) && @table[h].key == h
      end

      def [](h)
        @table[h]
      end

      # Probe the TT for saved search results.  If a valid entry is found, push the stored best move into
      # first_moves array. If stored result would cause cutoff of local search, return the stored result.
      def probe(node, depth, alpha, beta, in_check)
        if key_ok?(node.hash)
          $memory_calls += 1
          e = @table[node.hash]
          lower = e.lower
          upper = e.upper

          move = !e.move.nil? && node.avoids_check?(e.move, in_check) ? e.move : nil

          if lower.depth >= depth && lower.bound >= beta
            return move, lower.bound, lower.count
          end
          if upper.depth >= depth && upper.bound <= alpha
            return move, upper.bound, upper.count
          end
          return move, nil, nil
        end
        return nil, nil, nil  # sentinel indicating stored bounds were not sufficient to cause immediate cutoff.
      end

      # If an entry is available for node, return the best move stored from the previous search.
      def get_hash_move(node, in_check)
        if key_ok?(node.hash)
          e = @table[node.hash]  # if hash move is illegal, don't use it:
          return e.move unless e.move.nil? || !node.avoids_check?(e.move, in_check)
        end
        nil
      end

      # Store search results for node. Only overwrite existing entry if new information is based on search
      # of a larger subtree than the existing entry.
      def store(node, depth, count, result, alpha, beta, move)
        h = node.hash
        if @table.has_key?(h)
          e = @table[h]
          lower = e.lower
          upper = e.upper
          if count >= lower.count
            e.move = move
            upper.depth = depth
            upper.count = count
            if result <= alpha
              upper.bound = result
            else
              upper.bound = beta
            end
          end
          if count >= upper.count
            e.move = move
            lower.depth = depth
            lower.count = count
            if result >= beta
              lower.bound = result
            else
              lower.bound = alpha
            end
          end
        else 
          b = (result <= alpha) ? result : beta
          a = (result >= beta)  ? result : alpha
          @table[h] = TTEntry.new(h, TTBound.new(depth, count, a), TTBound.new(depth, count, b), move)
        end
        return result, count
      end

    end

    # When using 64-bit hash keys, Type I (hash collision) errors are extremely rare (once in 10,000+ searches 
    # at depth 6), but could theoretically still happen. These are particularly difficult to detect and can corrupt the
    # position / board representation when moves are made that are invalid for the current position.  If an error occurs
    # resulting from corruption of the internal board state, a HashCollisionError is raised.
    class HashCollisionError < StandardError 
    end
    

    # Zobrist Hashing
    #
    # These module helper methods implement Zobrist Hashing.  Each possible square and piece combination
    # is assigned a unique 64-bit integer key at startup.  A unique hash key for a given chess position can be
    # generated by merging (via XOR) the keys for each piece/square combination, and merging in keys representing
    # the side to move, castling rights, and any en-passant target square.

    def self.create_key  # Return a random 64-bit integer.
      SecureRandom::random_number(2**64)
    end

    # Associate each possible square and piece combination with its own random 64-bit key.
    PSQ_TABLE = Array.new(64) { Pieces::PIECE_ID.each_value.inject({}) { |h, id| h[id] = create_key; h } }
     
    # Associate each possible en-passant target square with its own random 64-bit key.
    ENP = Array.new(64) { create_key }

    SIDE = create_key
    # SIDE = 1  # Integer key representing a change in side-to-move. Used during make/unmake to update 
              # hash key of node.

    # Return the Zobrist key for the given en-passant target.
    def self.enp_key(enp_target)
      enp_target.nil? ? 0 : ENP[enp_target]
    end

    # Return the Zobrist key corresponding to the given piece and location.
    def self.psq_key(piece_symbol, square)
      PSQ_TABLE[square][piece_symbol]
    end


  end
end




