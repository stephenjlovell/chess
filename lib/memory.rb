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

          move = !e.move.nil? && node.evades_check?(e.move) ? e.move : nil

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

      # Special probing method for use with Enhanced Transposition Cutoffs (ETC).  Used to probe for child positions
      # found via a make/unmake of each move.
      def etc_probe(node, depth, alpha, beta, is_max)
        if ok?(node)
          $memory_calls += 1
          e = get(node)
          lower, upper = e.lower, e.upper

          if is_max
            if lower.depth >= depth && lower.bound >= beta
              return lower.bound, lower.count
            end
          else
            if upper.depth >= depth && upper.bound <= alpha
              return upper.bound, upper.count
            end
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

          if is_max
            if lower.depth >= depth && lower.bound >= beta
              return lower.bound, lower.count
            end
          else
            if upper.depth >= depth && upper.bound <= alpha
              return upper.bound, upper.count
            end
          end
        end
        return nil, nil
      end

      # If an entry is available for node, return the best move stored from the previous search.
      def get_hash_move(node)
        if ok?(node)
          e = get(node)  # if hash move is illegal, don't use it:
          return e.move unless e.move.nil? || !node.evades_check?(e.move)
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
          
          if count >= lower.count
            e.move = move
            if result <= alpha
              upper.depth, upper.count, upper.bound = depth, count, result
            else
              upper.depth, upper.count, upper.bound = depth, count, beta
            end
          end
          if count >= upper.count
            e.move = move
            if result >= beta
              lower.depth, lower.count, lower.bound = depth, count, result
            else
              lower.depth, lower.count, lower.bound = depth, count, alpha
            end
          end
        else 
          b = (result <= alpha) ? result : beta
          a = (result >= beta)  ? result : alpha
          @table[h] = TTEntry.new(h, TTBound.new(depth, count, a), TTBound.new(depth, count, b), move)
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
      hsh = Hash.new(0)
      Chess::Location::valid_locations.each { |loc| hsh[loc] = yield }
      return hsh
    end
    
    # Create a 12 element hash associating each piece symbol to a random 64-bit integer.
    def self.piece_hash 
      hsh = {}          
      [:wP, :wN, :wB, :wR, :wQ, :wK, :bP, :bN, :bB, :bR, :bQ, :bK].each { |sym| hsh[sym] = create_key }
      return hsh
    end

    def self.create_key  # Return a random 64-bit integer.
      SecureRandom::random_number(2**64)
    end

    # Associate each possible square and piece combination with its own random 64-bit key.
    PSQ = create_key_array { piece_hash } 

    # Associate each possible en-passant target square with its own random 64-bit key.
    ENP = create_key_array { create_key }

    SIDE = 1  # Integer key representing a change in side-to-move. Used during make/unmake to update 
              # hash key of node.

    # Return the Zobrist key for the given en-passant target.
    def self.enp_key(enp_target)
      enp_target.nil? ? 0 : ENP[enp_target]
    end

    # Return the Zobrist key corresponding to the given piece and location.
    def self.psq_key(piece, location)
      PSQ[location][piece.symbol]
    end

    # Return the Zobrist key corresponding to the given piece and square coordinates.
    def self.psq_key_by_square(r, c, sym)  # Alternative method for use with board object. 
      PSQ[Chess::Location::get_location_by_coordinates(r,c)][sym]
    end

  end
end




