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

module Application
  module Search # this module will define a search tree along with traversal algorithms for move selection.

    class << self
      # def min(x,y) # faster than using method supplied via Enumerable for binary comparisons.
      #   x < y ? x : y 
      # end
      # def max(x,y)  # faster than using method supplied via Enumerable for binary comparisons.
      #   x > y ? x : y
      # end

      def select_move
        root = Application::current_position
        depth = 5
        best_node = alpha_beta(root, root, nil, depth)
        best_node.value
        best_node.board.print
        return best_node.previous_move
      end 

      private
        def alpha_beta(node, root, best_node, depth_remaining, 
                       alpha = -1.0/0.0, beta = 1.0/0.0, maximize = true)
          if depth_remaining == 0
            return node.value
          elsif maximize # current node is a maximizing node
            is_root = node == root
            node.edges.each do |child|
              result = alpha_beta(child, root, best_node, 
                                  depth_remaining-1, alpha, beta, false)
              if result > alpha
                alpha = result
                best_node = child if is_root
              end
              break if beta <= alpha
            end
            return best_node if is_root
            return alpha
          else  # current node is a minimizing node
            node.edges.each do |child|
            is_root = node == root
              result = alpha_beta(child, root, best_node, 
                                  depth_remaining-1, alpha, beta, true)
              if result > beta
                beta = result
                best_node = child if is_root
              end
              break if beta <= alpha
            end
            return best_node if is_root
            return beta
          end
        end

        #color_value: 1.0 or -1.0
        # def negamax_alpha_beta(node, depth_remaining, alpha = -1.0/0.0, beta = 1.0/0.0, color_value)
        #   if depth_remaining == 0 || node.position.edges.empty?
        #     return node.value * color_value
        #   end
        #   best_value = -1.0/0.0
        #   node.edges.each do |child|
        #     value = -negamax_alpha_beta(child, depth_remaining-1, -beta, -alpha, -color)
        #     best_value = max(best_value, value)
        #     alpha = max(alpha, value)
        #     break if beta <= alpha
        #   end
        # end

    end

  end
end





