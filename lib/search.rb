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

    class TranspositionTable
      # this class generates a hash code for each explored position using a 
      # Zobrist hashing algorithm, and stores the value of each position.
      # An instance of this class is contained in each new Application::Game object.

      PIECE_INDEX = { nil => 0, wp: 1, wN: 2, wB: 3, wR: 4, wQ: 5, wK: 6,
                      bP: 7, bN: 8, bB: 9, bR: 10, bQ: 11, bK: 12 }

      def initialize
        @table = {}
        @bitstrings = create_bitstring_array
      end

      def memoize(position) # memoizes the inspected node value
        @table[hash(position)] = position.value
      end

      def hash(position)  # generates a unique hash corresponding to position.

      end

      def remembers?(position)
        !!@table[hash(position)]
      end

      def keygen(board)
        key = []
        (2..9).each do |row|
          (2..9).each do |column|
            key << @bitstrings[row][column][board[row, column]]   
          end
        end
        return key
      end

      private
        def create_bitstring_array
          Array.new(8, Array.new(8, new_piece_hash ))
        end

        def new_piece_hash
          hsh = {}
          [ nil, :wP, :wN, :wB, :wR, :wQ, :wK, 
            :bP, :bN, :bB, :bR, :bQ, :bK ].each do |sym|
            hsh[sym] = SecureRandom::uuid
          end
          return hsh
        end
    end

    def self.select_position
      $total_calls = 0
      root = Application::current_position
      depth = 4
      alpha_beta(root, root, depth)
      # negamax_alpha_beta(root, root, depth)
    end 

    private
      def self.alpha_beta(node, root, depth_remaining, alpha = -1.0/0.0, 
                          beta = 1.0/0.0, maximize = true)
        $total_calls += 1
        if depth_remaining <= 0
          return node.value
        elsif maximize # current node is a maximizing node
          is_root = node == root
          best_node = nil
          node.edges.each do |child|
            result = alpha_beta(child, root, depth_remaining-1, alpha, beta, false)
            if result > alpha
              alpha = result
              best_node = child if is_root
            end
            break if beta <= alpha
          end
          return is_root ? best_node : alpha
        else  # current node is a minimizing node
          is_root = node == root
          best_node = nil
          node.edges.each do |child|
            result = alpha_beta(child, root, depth_remaining-1, alpha, beta, true)
            if result > beta
              beta = result
              best_node = child if is_root
            end
            break if beta <= alpha
          end
          return is_root ? best_node : beta
        end
      end

      # color_value: 1.0 or -1.0
      def self.negamax_alpha_beta(node, root, depth_remaining, alpha = -1.0/0.0, 
                                  beta = 1.0/0.0, color = 1.0)
        $total_calls += 1
        return node.value * color if depth_remaining <= 0
        best_child = nil
        best_value = -1.0/0.0
        node.edges.each do |child|
          value = -negamax_alpha_beta(child, root, depth_remaining-1, -beta, -alpha, -color)
          if value > best_value
            best_value = value
            best_child = child
          end
          alpha = alpha > value ? alpha : value 
          break if beta <= alpha
        end
        return node == root ? best_child : best_value
      end

      def self.mtd_f
        # this algorithm will incrementally set the alpha-beta search window 
        # and call either self.alpha_beta or self.negamax
      end

  end
end





