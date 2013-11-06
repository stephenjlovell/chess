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
      @root = nil

      def root
        @root ||= Node.new(Application::current_position)
      end

      def min(x,y) # faster than using method supplied via Enumerable for binary comparisons.
        x < y ? x : y 
      end

      def max(x,y)  # faster than using method supplied via Enumerable for binary comparisons.
        x > y ? x : y
      end 

      # initial call:  alphabeta(Search::root), 4)
      def alpha_beta(node, depth_remaining, alpha = -1.0/0.0, beta = 1.0/0.0, maximize = true)
        if depth_remaining == 0 || node.position.edges.empty?
          return node.value
        elsif maximize # current node is a maximizing node
          node.edges.each do |child|
            alpha = max(alpha, alpha_beta(child, depth_remaining-1, alpha, beta, false))
            break if beta <= alpha
          end
          return alpha
        else  # current node is a minimizing node
          node.edges.each do |child|
            beta = min(beta, alpha_beta(child, depth_remaining-1, alpha, beta, true))
            break if beta <= alpha
          end
          return beta
        end
      end

      #color_value: 1.0 or -1.0
      def negamax_alpha_beta(node, depth_remaining, alpha = -1.0/0.0, beta = 1.0/0.0, color_value)

        if depth_remaining == 0 || node.position.edges.empty?
          return node.value * color_value
        end
        best_value = -1.0/0.0
        node.edges.each do |child|
          value = -negamax_alpha_beta(child, depth_remaining-1, -beta, -alpha, -color)
          best_value = max(best_value, value)
          alpha = max(alpha, value)
          break if beta <= alpha
        end

      end

    end

  end
end





