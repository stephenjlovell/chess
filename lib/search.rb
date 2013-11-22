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
      # A single instance of this class is contained in Application::Game instances.

      def initialize
        @table = {}
        @bitstrings = create_bytestring_array
      end

      def memoize(position) # memoizes and returns the inspected node value
        h = hash(position.board)
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
        def hash(board)  # generates a unique hash key corresponding to position.
          key = 0
          (2..9).each do |row|
            (2..9).each do |column|
              sym = board[row, column]
              unless sym.nil?
                str = @bitstrings[row-2][column-2][sym]
                str.unpack('L*').each { |i| key ^= i } # unpack to 64-bit unsigned long ints, 
              end                                      # and merge into key via bitwise XOR.
            end
          end
          return key
        end

        def create_bytestring_array
          Array.new(8, Array.new(8, new_piece_hash ))
        end

        def new_piece_hash
          hsh = {}
          [ :wP, :wN, :wB, :wR, :wQ, :wK, 
            :bP, :bN, :bB, :bR, :bQ, :bK ].each do |sym|
            hsh[sym] = SecureRandom::random_bytes
          end
          return hsh
        end
    end

    def self.select_position
      $main_calls = 0
      $quiescence_calls = 0
      root = Application::current_position
      depth = 5
      alpha_beta(root, root, depth)
    end 

    private
      def self.alpha_beta(node, root, depth_remaining, alpha = -1.0/0.0, 
                          beta = 1.0/0.0, maximize = true)
        $main_calls += 1
        return quiesence(node, root, 4, alpha, beta, !maximize) if depth_remaining <= 0
        if maximize # current node is a maximizing node
          best_node = nil
          node.edges.each do |child|
            result = alpha_beta(child, root, depth_remaining-1, alpha, beta, false)
            if result > alpha
              alpha = result
              best_node = child
            end
            break if beta <= alpha
          end
          return node == root ? best_node : alpha
        else  # current node is a minimizing node
          best_node = nil
          node.edges.each do |child|
            result = alpha_beta(child, root, depth_remaining-1, alpha, beta, true)
            if result > beta
              beta = result
              best_node = child
            end
            break if beta <= alpha
          end
          return node == root ? best_node : beta
        end
      end # end alpha_beta

      def self.quiesence(node, root, depth_remaining, alpha = -1.0/0.0, 
                          beta = 1.0/0.0, maximize = true)
        # This algorithm continues expanding only those child nodes resulting from
        # capture moves.  This reduces the horizon effect on alpha beta searches.
        $quiescence_calls += 1
        return Application::current_game.tt.memoize(node) if depth_remaining <= 0
        tactical_edges = node.tactical_edges
        return Application::current_game.tt.memoize(node) if tactical_edges.empty?          
        if maximize
          tactical_edges.each do |child|
            result = quiesence(child, root, depth_remaining-1, alpha, beta, true)
            if result > alpha
              alpha = result
            end
            break if beta <= alpha
          end
          return alpha
        else
          tactical_edges.each do |child|
            result = quiesence(child, root, depth_remaining-1, alpha, beta, false)
            if result > beta
              beta = result
            end
            break if beta <= alpha
          end
          return beta
        end
      end # end quiescence

      def self.mtd_f
        # this algorithm will incrementally set the alpha-beta search window 
        # and call either self.alpha_beta or self.negamax
      end

      # color_value: 1.0 or -1.0
      # def self.negamax_alpha_beta(node, root, depth_remaining, alpha = -1.0/0.0, 
      #                             beta = 1.0/0.0, color = 1.0)
      #   $main_calls += 1
      #   return node.value * color if depth_remaining <= 0
      #   best_child = nil
      #   best_value = -1.0/0.0
      #   node.edges.each do |child|
      #     value = -negamax_alpha_beta(child, root, depth_remaining-1, -beta, -alpha, -color)
      #     if value > best_value
      #       best_value = value
      #       best_child = child
      #     end
      #     alpha = alpha > value ? alpha : value 
      #     break if beta <= alpha
      #   end
      #   return node == root ? best_child : best_value
      # end

  end
end





