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

require 'SecureRandom'

module Application
  module Search # this module will define a search tree along with traversal algorithms for move selection.

    class TranspositionTable # this class generates a hash code for each explored position  
      # using a Zobrist hashing algorithm, and stores the value of each position.
      # A single instance of this class is contained in Application::Game instances.

      def initialize
        @table = {}
      end

      def memoize(position) # memoizes and returns the inspected node value
        h = hash(position.board)
        # store h in position object instance variable to enable incremental calculation of
        # hashes for child nodes.
        @table[h] = position.value unless @table[h]
        return @table[h]
      end

      def remembers?(board)
        !!@table[hash(board)]
      end

      def [](key)
        @table[key]
      end

      private
      def self.create_bytestring_array
        Array.new(8, Array.new(8, new_piece_hash ))
      end
      
      def self.new_piece_hash # creates a 12 element hash associating each piece to a 
        hsh = {}              # set of 16 random bytes packed in a string.
        [ :wP, :wN, :wB, :wR, :wQ, :wK, 
          :bP, :bN, :bB, :bR, :bQ, :bK ].each do |sym|
          hsh[sym] = SecureRandom::random_bytes
        end
        return hsh
      end

      BSTR = create_bytestring_array

      def hash(board)  # generates a unique hash key corresponding to position.
        key = 0
        board.each_square_with_location do |row, column, sym|
          BSTR[row-2][column-2][sym].unpack('L*').each { |i| key ^= i } unless sym.nil? 
        end  # unpack to 64-bit unsigned long ints and merge into key via bitwise XOR.
        return key
      end

    end # end TranspostionTable class

    def self.select_position
      $main_calls = 0
      $quiescence_calls = 0
      root = Application::current_position
      depth = 6
      # return iterative_deepening(root, depth)
      best_node, value = get_best_node(root, depth)
      return best_node
    end 

    private

    def self.iterative_deepening(root, depth)
      value = Application::current_game.tt.memoize(root) # initial guess
      (1..depth).each do |d|
        best_node, value = mtdf(root, value, depth)
        break if Application::current_game.clock.time_up?
      end
      return best_node
    end

    def self.mtdf(root, value, depth) # this algorithm will incrementally set the 
      g = value                        # alpha-beta search window and call alpha_beta.
      upper_bound = 1.0/0
      lower_bound = -1.0/0
      until lower_bound >= upper_bound do
        puts lower_bound.to_s + " - " + upper_bound.to_s
        beta = g == lower_bound ? g+1 : g
        best_node, g = get_best_node(root, depth, beta-1, beta)
        if g < beta then upper_bound = g else lower_bound = g end
      end
      return best_node, g
    end

    def self.get_best_node(root, depth, alpha = -1.0/0.0, beta = 1.0/0.0)
      best_node = nil
      root.edges.each do |child|
        result = alpha_beta(child, root, depth-1, alpha, beta, false)
        if result > alpha
          alpha = result
          best_node = child
        end
        break if beta <= alpha
      end
      return best_node, alpha
    end

    def self.alpha_beta(node, root, depth, alpha = -1.0/0.0, beta = 1.0/0.0, maximize = true)
      $main_calls += 1
      return quiesence(node, root, 1, alpha, beta, !maximize) if depth <= 0
      if maximize
        node.edges.each do |child|
          result = alpha_beta(child, root, depth-1, alpha, beta, false)
          alpha = result if result > alpha
          break if beta <= alpha
        end
        return alpha
      else
        node.edges.each do |child|
          result = alpha_beta(child, root, depth-1, alpha, beta, true)
          beta = result if result > beta
          break if beta <= alpha
        end
        return beta
      end
    end

    def self.quiesence(node, root, depth, alpha = -1.0/0.0, beta = 1.0/0.0, maximize = true)
      # This algorithm continues expanding only those child nodes resulting from
      # capture moves.  This reduces the 'horizon effect' on alpha beta searches.
      $quiescence_calls += 1
      return Application::current_game.tt.memoize(node) if depth <= 0
      tactical_edges = node.tactical_edges
      return Application::current_game.tt.memoize(node) if tactical_edges.empty?          
      if maximize
        tactical_edges.each do |child|
          result = quiesence(child, root, depth-1, alpha, beta, true)
          alpha = result if result > alpha
          break if beta <= alpha
        end
        return alpha
      else
        tactical_edges.each do |child|
          result = quiesence(child, root, depth-1, alpha, beta, false)
          beta = result if result > beta
          break if beta <= alpha
        end
        return beta
      end
    end # end quiescence

  end
end



