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
      # max_depth = 6
      # return iterative_deepening(root, max_depth)
      # best_node, value = get_best_node_with_memory(root, max_depth)
      best_node, value = mtdf(root, 0, 20)
      return best_node
    end 

    private
    def self.iterative_deepening(root, depth)
      puts "iterative_deepening(#{root}, #{depth})"
      pos = Application::current_position
      guess = pos.parent.value || pos.value
      best_node = nil
      (1..depth).each do |d|
        $iterative_depth = d
        puts "\tmtdf(#{root}, #{guess}, #{d})"
        best_node, value = mtdf(root, guess, d)
        guess = value
        if Application::current_game.clock.time_up?
          puts "evaluation time ran out after depth #{d}"
          break
        end
        # at each depth d, need to make sure the values discovered so far are used to order moves used in depth d+1.
        # this will increase the number of alpha-beta cutoffs.
      end
      return best_node, value
    end

    def self.mtdf(root, value, depth) # this algorithm will incrementally set the 
      g = value                       # alpha-beta search window and call alpha_beta.
      puts "mtdf(#{root}, #{value}, #{depth})"
      upper_bound = $INF
      lower_bound = -$INF
      while lower_bound < upper_bound do
        beta = (g == lower_bound ? g+1 : g)
        best_node, g = get_best_node_with_memory(root, depth, beta-1, beta)
        if g < beta then upper_bound = g else lower_bound = g end
      end
      return best_node, g
    end

    # def self.get_best_node(root, depth, alpha = -$INF, beta = $INF)
    #   best_node = nil
    #   root.edges.each do |child|
    #     result = alpha_beta_with_memory(child, depth-1, alpha, beta, false)
    #     if result > alpha
    #       alpha = result
    #       best_node = child
    #     end
    #     break if beta <= alpha
    #   end
    #   return best_node, alpha
    # end

    # def self.alpha_beta(node, depth, alpha=-$INF, beta=$INF, maximize=true)
    #   $main_calls += 1
    #   return quiesence(node, 1, alpha, beta, !maximize) if depth <= 0
    #   if maximize
    #     node.edges.each do |child|
    #       result = alpha_beta(child, depth-1, alpha, beta, false)
    #       alpha = result if result > alpha
    #       break if beta <= alpha
    #     end
    #     return alpha
    #   else
    #     node.edges.each do |child|
    #       result = alpha_beta(child, depth-1, alpha, beta, true)
    #       beta = result if result > beta
    #       break if beta <= alpha
    #     end
    #     return beta
    #   end
    # end

    # def self.quiesence(node, depth, alpha=-$INF, beta=$INF, maximize=true) # This algorithm only expands
    # # child nodes resulting from capture moves. This reduces the 'horizon effect' on alpha beta searches.
    #   $quiescence_calls += 1
    #   return Application::current_game.tt.memoize(node,depth_searched, alpha, beta) if depth <= 0
    #   tactical_edges = node.tactical_edges
    #   return Application::current_game.tt.memoize(node, depth_searched, alpha, beta) if tactical_edges.empty?          
    #   if maximize
    #     tactical_edges.each do |child|
    #       result = quiesence(child, depth-1, alpha, beta, true)
    #       alpha = result if result > alpha
    #       break if beta <= alpha
    #     end
    #     return alpha
    #   else
    #     tactical_edges.each do |child|
    #       result = quiesence(child, depth-1, alpha, beta, false)
    #       beta = result if result > beta
    #       break if beta <= alpha
    #     end
    #     return beta
    #   end
    # end # end quiescence

    def self.get_best_node_with_memory(root, depth, alpha=-$INF, beta=$INF)
      puts "get_best_node_with_memory(#{root}, #{depth}, #{alpha}, #{beta})"
      $main_calls += 1
      tt = Application::current_game.tt
      entry = tt.retrieve(root)
      if entry && entry.depth >= depth
        return entry.best_node, entry.value if entry.type == :exact_value
        if entry.type == :lower_bound && entry.value > alpha
          alpha = entry.value 
        elsif entry.type == :upper_bound && entry.value < beta
          beta = entry.value
        end
        return entry.best_node, entry.value if alpha > beta
      end

      best_value = -$INF
      best_node = nil
      root.edges.each do |child|
        result = -alpha_beta_with_memory(child, depth-1, -beta, -alpha)
        if result > best_value
          best_value = result 
          best_node = child
        end
        alpha = best_value if best_value > alpha
        break if best_value > beta
      end

      if best_value <= alpha
        tt.store(root, depth, :lower_bound, best_value, best_node)
      elsif best_value >= beta
        tt.store(root, depth, :upper_bound, best_value, best_node)
      else
        tt.store(root, depth, :exact_value, best_value, best_node)
      end
      return best_node, best_value
    end

    def self.alpha_beta_with_memory(node, depth, alpha=-$INF, beta=$INF)
      # puts "\talpha_beta_with_memory(#{node}, #{depth}, #{alpha}, #{beta})"
      $main_calls += 1
      tt = Application::current_game.tt

      entry = tt.retrieve(node)
      if entry && entry.depth >= depth
        return entry.value if entry.type == :exact_value
        if entry.type == :lower_bound && entry.value > alpha
          alpha = entry.value 
        elsif entry.type == :upper_bound && entry.value < beta
          beta = entry.value
        end
        return entry.value if alpha > beta
      end

      if depth <= 0
        value = -quiesence_with_memory(node, -beta, -alpha)
        if value <= alpha
          tt.store(node, depth, :lower_bound, value)  # what is saved for best_node?
        elsif value >= beta
          tt.store(node, depth, :upper_bound, value)
        else
          tt.store(node, depth, :exact_value, value)
        end
        return value
      end
      best_value = -$INF
      best_node = nil
      node.edges.each do |child|
        result = -alpha_beta_with_memory(child, depth-1, -beta, -alpha)
        if result > best_value
          best_value = result 
          best_node = child
        end
        alpha = best_value if best_value > alpha
        break if best_value > beta
      end

      if best_value <= alpha
        tt.store(node, depth, :lower_bound, best_value, best_node)
      elsif best_value >= beta
        tt.store(node, depth, :upper_bound, best_value, best_node)
      else
        tt.store(node, depth, :exact_value, best_value, best_node)
      end
      return best_value
    end

    def self.quiesence_with_memory(node, alpha, beta)
      # puts "\tquiesence_with_memory(#{node}, #{alpha}, #{beta})"
      $quiescence_calls += 1
      best_value = -$INF
      node.tactical_edges.each do |child|
        best_value = max(child.value, best_value)
        alpha = best_value if best_value > alpha
        break if best_value > beta
      end
      return best_value
    end

    def self.max(a,b)
      a > b ? a : b
    end

    def self.min(a,b)
      a < b ? a : b
    end

  end
end



