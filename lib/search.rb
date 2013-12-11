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
  module Search # this module will define tree traversal algorithms for move selection.

    def self.select_position
      $main_calls = 0
      $quiescence_calls = 0
      root = Application::current_position
      max_depth = 6
      puts "iterative_deepening(#{root}, #{max_depth})"
      return iterative_deepening(root, max_depth)
      # best_node, value = get_best_node(root, $max_depth)
      # return best_node
    end 

    private

    def self.iterative_deepening(root, depth)
      guess = Application::current_game.tt.memoize(root, depth, -$INF, $INF) # initial guess
      best_node = nil
      (1..depth).each do |d|
        $iterative_depth = d
        puts "\tmtdf(#{root}, #{guess}, #{d})"
        best_node, value = mtdf(root, guess, d)
        guess = value
        # break if Application::current_game.clock.time_up?
      end
      return best_node
    end

    def self.mtdf(root, value, depth) # this algorithm will incrementally set the 
      g = value                       # alpha-beta search window and call alpha_beta.
      upper_bound = $INF
      lower_bound = -$INF
      while lower_bound < upper_bound do
        beta = (g == lower_bound ? g+1 : g)
        best_node, g = get_best_node_with_memory(root, depth, beta-1, beta)
        if g < beta then upper_bound = g else lower_bound = g end
      end
      return best_node, g
    end

    def self.get_best_node(root, depth, alpha = -$INF, beta = $INF)
      best_node = nil
      root.edges.each do |child|
        result = alpha_beta_with_memory(child, depth-1, alpha, beta, false)
        if result > alpha
          alpha = result
          best_node = child
        end
        break if beta <= alpha
      end
      return best_node, alpha
    end

    def self.alpha_beta(node, depth, alpha=-$INF, beta=$INF, maximize=true)
      $main_calls += 1
      return quiesence(node, 1, alpha, beta, !maximize) if depth <= 0
      if maximize
        node.edges.each do |child|
          result = alpha_beta(child, depth-1, alpha, beta, false)
          alpha = result if result > alpha
          break if beta <= alpha
        end
        return alpha
      else
        node.edges.each do |child|
          result = alpha_beta(child, depth-1, alpha, beta, true)
          beta = result if result > beta
          break if beta <= alpha
        end
        return beta
      end
    end

    def self.quiesence(node, depth, alpha=-$INF, beta=$INF, maximize=true) # This algorithm only expands
    # child nodes resulting from capture moves. This reduces the 'horizon effect' on alpha beta searches.
      $quiescence_calls += 1
      depth_searched = $iterative_depth - depth
      return Application::current_game.tt.memoize(node,depth_searched, alpha, beta) if depth <= 0
      tactical_edges = node.tactical_edges
      return Application::current_game.tt.memoize(node, depth_searched, alpha, beta) if tactical_edges.empty?          
      if maximize
        tactical_edges.each do |child|
          result = quiesence(child, depth-1, alpha, beta, true)
          alpha = result if result > alpha
          break if beta <= alpha
        end
        return alpha
      else
        tactical_edges.each do |child|
          result = quiesence(child, depth-1, alpha, beta, false)
          beta = result if result > beta
          break if beta <= alpha
        end
        return beta
      end
    end # end quiescence

    def self.get_best_node_with_memory(root, depth, alpha=-$INF, beta=$INF)
      puts "\t\t\tget_best_node_with_memory(#{root}, #{depth}, #{alpha}, #{beta}"
      tt = Application::current_game.tt
      
      # entry = tt.retrieve(root)
      # if entry
      #   return entry.lower_bound if entry.lower_bound >= beta
      #   return entry.upper_bound if entry.upper_bound <= alpha
      #   alpha = max(alpha, entry.lower_bound)
      #   beta = min(beta, entry.upper_bound)
      # end

      # if depth <= 0
      #   result = tt.memoize(root, alpha, beta, depth)
      #   puts "leaf node with value #{result}" 
      # else
        result = -$INF
        a = alpha
        best_node = nil
        root.edges.each do |child|
          result = max(result, alpha_beta_with_memory(child, depth-1, a, beta, false))
          if result > a
            a = result
            best_node = child
          end
          break if result < beta
        end
      # end
      # upper_bound = $INF
      # lower_bound = -$INF
      # if result <= alpha 
      #   upper_bound = result
      # elsif result < beta
      #   lower_bound = result
      #   upper_bound = result
      # end
      # lower_bound = result if result >= beta
      # tt.store(root, depth, lower_bound, upper_bound, result)
      # puts "the end!"
      return best_node, result
    end

    def self.alpha_beta_with_memory(node, depth, alpha=-$INF, beta=$INF, maximize=true)
      puts "\t\t\talpha_beta_with_memory(#{node}, #{depth}, #{alpha}, #{beta}, #{maximize}"
      tt = Application::current_game.tt
      
      entry = tt.retrieve(node)
      if entry
        return entry.lower_bound if entry.lower_bound >= beta
        return entry.upper_bound if entry.upper_bound <= alpha
        alpha = max(alpha, entry.lower_bound)
        beta = min(beta, entry.upper_bound)
      end

      if depth <= 0
        result = tt.memoize(node, alpha, beta, depth)
        puts "leaf node with value #{result}" 
      elsif maximize
        result = -$INF
        a = alpha
        node.edges.each do |child|
          result = max(result, alpha_beta_with_memory(child, depth-1, a, beta, false))
          a = max(a, result)
          break if result < beta
        end
      else  # min node
        result = $INF
        b = beta
        node.edges.each do |child|
          result = min(result, alpha_beta_with_memory(child, depth-1, alpha, b, true))
          b = min(b,result)
          break if result > alpha
        end
      end

      upper_bound = $INF
      lower_bound = -$INF
      if result <= alpha 
        upper_bound = result
      elsif result < beta
        lower_bound = result
        upper_bound = result
      end
      lower_bound = result if result >= beta
      tt.store(node, depth, lower_bound, upper_bound, result)
      puts "the end!"
      return result
    end

    def self.max(a,b)
      a > b ? a : b
    end

    def self.min(a,b)
      a < b ? a : b
    end

  end
end



