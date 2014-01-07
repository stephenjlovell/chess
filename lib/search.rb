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
  module Search # this module defines tree traversal algorithms for move selection.

    def self.select_position(root)
      $tt = Application::current_game.tt
      best_node, value = iterative_deepening(root, 8)
      #   $main_calls = 0
      #   $quiescence_calls = 0
      # best_node, value = get_best_node(root, 5)
      return best_node
    end 

    private
    def self.iterative_deepening(root, depth)
      # puts "iterative_deepening(#{root}, #{depth})"
      pos = Application::current_position
      $evaluation_calls = 0
      guess = pos.parent ? pos.parent.value : pos.value
      best_node = nil
      value = -$INF

      puts "depth | main nodes | quiescence nodes | evaluations"

      (1..depth).each do |d|
        $main_calls = 0
        $quiescence_calls = 0
        $evaluation_calls = 0
        best_node, value = mtdf(root, guess, d)
        puts "#{d}    | #{$main_calls}           | #{$quiescence_calls} | #{$evaluation_calls}"
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
      # puts "\tmtdf(#{root}, #{value}, #{depth})"
      upper_bound = $INF
      lower_bound = -$INF
      while lower_bound < upper_bound do
        beta = (g == lower_bound ? g+1 : g)
        best_node, g = get_best_node(root, depth, beta-1, beta)
        if g < beta then upper_bound = g else lower_bound = g end
      end
      return best_node, g
    end

    def self.get_best_node(root, depth, alpha=-$INF, beta=$INF)
      # puts "\t\tget_best_node(#{root}, #{depth}, #{alpha}, #{beta})"
      $main_calls += 1
      entry = $tt.retrieve(root)
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
      root.edges.each do |move|
        child = move.create_position
        result = -alpha_beta(child, depth-1, -beta, -alpha)
        if result > best_value
          best_value = result 
          best_node = child
        end
        alpha = best_value if best_value > alpha
        break if best_value > beta
      end

      if best_value <= alpha
        $tt.store(root, depth, :lower_bound, best_value, best_node)
      elsif best_value >= beta
        $tt.store(root, depth, :upper_bound, best_value, best_node)
      else
        $tt.store(root, depth, :exact_value, best_value, best_node)
      end
      return best_node, best_value
    end

    def self.alpha_beta(node, depth, alpha=-$INF, beta=$INF)
      # puts "\t\t\talpha_beta(#{node}, #{depth}, #{alpha}, #{beta})"
      $main_calls += 1

      entry = $tt.retrieve(node)
      if entry && entry.depth >= depth
        return entry.value if entry.type == :exact_value
        if entry.type == :lower_bound && entry.value > alpha
          alpha = entry.value 
        elsif entry.type == :upper_bound && entry.value < beta
          beta = entry.value
        end
        return entry.value if alpha > beta
      end

      if depth <= 2
        value = -quiescence(node, depth-1, -beta, -alpha)
        if value <= alpha
          $tt.store(node, depth, :lower_bound, value)  # what is saved for best_node?
        elsif value >= beta
          $tt.store(node, depth, :upper_bound, value)
        else
          $tt.store(node, depth, :exact_value, value)
        end
        return value
      end

      best_value = -$INF
      best_node = nil
      node.edges.each do |move|
        child = move.create_position
        result = -alpha_beta(child, depth-1, -beta, -alpha)
        if result > best_value
          best_value = result 
          best_node = child
        end
        alpha = best_value if best_value > alpha
        break if best_value > beta
      end

      if best_value <= alpha
        $tt.store(node, depth, :lower_bound, best_value, best_node)
      elsif best_value >= beta
        $tt.store(node, depth, :upper_bound, best_value, best_node)
      else
        $tt.store(node, depth, :exact_value, best_value, best_node)
      end
      return best_value
    end

    def self.quiescence(node, depth, alpha, beta)
      # puts "\t\t\t\tquiescence(#{node}, #{alpha}, #{beta})"
      $quiescence_calls += 1

      entry = $tt.retrieve(node)
      if entry && entry.depth >= depth
        return entry.value if entry.type == :exact_value
        if entry.type == :lower_bound && entry.value > alpha
          alpha = entry.value 
        elsif entry.type == :upper_bound && entry.value < beta
          beta = entry.value
        end
        return entry.value if alpha > beta
      end

      value = entry ? entry.value : node.value
      
      if depth <= 0
        if value <= alpha
          $tt.store(node, depth, :lower_bound, value)  # what is saved for best_node?
        elsif value >= beta
          $tt.store(node, depth, :upper_bound, value)
        else
          $tt.store(node, depth, :exact_value, value)
        end
        return value
      end

      # assume 'standing pat' lower bound:
      return beta if value >= beta
      alpha = score if value > alpha

      best_value = -$INF   # cannot assume that any child nodes
      best_node = nil
      node.tactical_edges.each do |move|
        child = move.create_position
        result = -quiescence(child, depth-1, -beta, -alpha)
        if result > best_value
          best_value = result 
          best_node = child
        end
        alpha = best_value if best_value > alpha
        break if best_value > beta
      end

      if best_value <= alpha
        $tt.store(node, depth, :lower_bound, alpha, best_node)
      elsif best_value >= beta
        $tt.store(node, depth, :upper_bound, alpha, best_node)
      else
        $tt.store(node, depth, :exact_value, alpha, best_node)
      end
      return alpha
    end

    def self.max(a,b)
      a > b ? a : b
    end

    def self.min(a,b)
      a < b ? a : b
    end

  end
end



