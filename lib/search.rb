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

    class Node # this class defines a single node in the search tree
      attr_accessor :position

      def initialize(position)
        @position = position
      end

      def edges 
        @edges ||= @position.get_moves.collect do |move|
          Node.new(Position::create_position(@position, move))
        end
      end

      def value
        @value ||= Evaluation::evaluate(@position)
      end

      def value=(value)
        @value = value
      end

    end

    def self.root
      Node.new(Application::current_position)
    end

    # initial call:  alphabeta(Search::root), 4)
    def self.alpha_beta(node, depth_remaining, alpha = -1.0/0.0, beta = 1.0/0.0, maximize = true)
      if depth_remaining == 0 || node.position.edges.empty?
        return node.value
      elsif maximize # current node is a maximizing node
        node.edges.each do |child|
          alpha = [alpha, alpha_beta(child, depth_remaining-1, alpha, beta, false)].max
          break if beta <= alpha
        end
        return alpha
      else  # current node is a minimizing node
        node.edges.each do |child|
          beta = [beta, alpha_beta(child, depth_remaining-1, alpha, beta, true)].min
          break if beta <= alpha
        end
        return beta
      end
    end

  end
end


