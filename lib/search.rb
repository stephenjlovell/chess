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

    def self.select_move
      root = Application::current_position
      depth = 5
      # best_node = alpha_beta(root, root, nil, depth)
      best_node = negamax_alpha_beta(root, root, depth)
      puts best_node.value
      puts "#{$total_calls} total nodes explored."
      best_node.board.print
      return best_node.previous_move
    end 

    private
      def self.alpha_beta(node, root, best_node, depth_remaining, 
                          alpha = -1.0/0.0, beta = 1.0/0.0, maximize = true)
        $total_calls += 1
        if depth_remaining <= 0
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
          return is_root ? best_node : alpha
        else  # current node is a minimizing node
          is_root = node == root
          node.edges.each do |child|
            result = alpha_beta(child, root, best_node, 
                                depth_remaining-1, alpha, beta, true)
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

  end
end





