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

    # initial call:  alphabeta(Node.new(Application::current_position), 4, -1.0/0.0, 1.0/0.0, true)

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


