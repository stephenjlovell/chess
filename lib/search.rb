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

    class Strategy
      attr_reader :algorithm

      def initialize(root, algorithm = :iterative_deepening_mtdf)
        @root, @algorithm = root, algorithm
      end

      def select_position
        raise "search algorithm #{@algorithm} is unavailable" unless respond_to?(@algorithm)
        best_node, value = send(@algorithm)
      end

      def iterative_deepening_mtdf(depth = 7)
        iterative_deepening(depth) do |guess, d|
          mtdf(guess, d)
        end
      end

      def iterative_deepening_alpha_beta(depth = 7)
        iterative_deepening(depth) do |guess, d|
          alpha_beta(d)
        end
      end

      def iterative_deepening(depth)
        $evaluation_calls = 0
        guess = @root.parent ? @root.parent.value : @root.value
        best_node = nil
        value = -$INF
        puts "\ndepth | main nodes | quiescence nodes | total  nodes | evaluations | memory access"
        (1..depth).each do |d|
          Search::reset_counters
          best_node, value = yield(guess, d)
          puts "#{d} | #{$main_calls} | #{$quiescence_calls} | #{$main_calls+$quiescence_calls} | #{$evaluation_calls} | #{$memory_calls}"
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

      def mtdf(g = nil, depth = 7) # this algorithm will incrementally set the alpha-beta search window and call alpha_beta.
        g ||= @root.value
        upper_bound = $INF
        lower_bound = -$INF
        while lower_bound < upper_bound do
          beta = (g == lower_bound ? g+1 : g)
          best_node, g = alpha_beta(depth, beta-1, beta)
          if g < beta then upper_bound = g else lower_bound = g end
        end
        return best_node, g
      end

      def alpha_beta(depth = 7, alpha=-$INF, beta=$INF) # change these names
        $main_calls += 1

        entry = $tt.retrieve(@root)
        if entry && entry.depth >= depth
          if entry.type == :exact_value
            return entry.best_node, entry.value 
          elsif entry.type == :lower_bound && entry.value > alpha
            alpha = entry.value 
          elsif entry.type == :upper_bound && entry.value < beta
            beta = entry.value
          end
          return entry.best_node, entry.value if alpha >= beta
        end

        best_value = -$INF
        best_node = nil
        edge_count = 0
        @root.edges.each do |move|
          edge_count += 1
          child = move.create_position
          result = -alpha_beta_main(child, depth-1, -beta, -alpha)
          if result > best_value
            best_value = result 
            best_node = child
          end
          alpha = best_value if best_value > alpha
          break if best_value >= beta
        end

        if edge_count == 0 && @root.in_check?
          puts "CHECKMATE!"
          return -$INF
        end

        if best_value <= alpha
          $tt.store(@root, depth, :lower_bound, best_value, best_node)
        elsif best_value >= beta
          $tt.store(@root, depth, :upper_bound, best_value, best_node)
        else
          $tt.store(@root, depth, :exact_value, best_value, best_node)
        end
        return best_node, best_value
      end

      def alpha_beta_main(node, depth, alpha=-$INF, beta=$INF)
        $main_calls += 1

        entry = $tt.retrieve(node)
        if entry && entry.depth >= depth
          if entry.type == :exact_value
            return entry.value 
          elsif entry.type == :lower_bound && entry.value > alpha
            alpha = entry.value 
          elsif entry.type == :upper_bound && entry.value < beta
            beta = entry.value
          end
          return entry.value if alpha >= beta
        end

        if depth == 0 # || terminal node (checkmate)
          
          value = -quiescence(node, 1, -beta, -alpha)

          if value <= alpha
            $tt.store(node, depth, :lower_bound, value)  # what is saved for best_node?
          elsif value >= beta
            $tt.store(node, depth, :upper_bound, value)
          else
            $tt.store(node, depth, :exact_value, value)
          end
          return value
        end

        best_value = -$INF  # this is sufficient for finding checkmate.
        best_node = nil
        edge_count = 0
        node.edges.each do |move|
          edge_count += 1
          child = move.create_position
          result = -alpha_beta_main(child, depth-1, -beta, -alpha)
          if result > best_value
            best_value = result 
            best_node = child
          end
          alpha = best_value if best_value > alpha
          break if best_value >= beta
        end

        if edge_count == 0 && node.in_check?
          puts "CHECKMATE!"
          return -$INF
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

      def quiescence(node, depth, alpha, beta)
        $quiescence_calls += 1

        entry = $tt.retrieve(node)
        if entry && entry.depth >= depth
          if entry.type == :exact_value
            return entry.value 
          elsif entry.type == :lower_bound && entry.value > alpha
            alpha = entry.value 
          elsif entry.type == :upper_bound && entry.value < beta
            beta = entry.value
          end
          return entry.value if alpha >= beta
        end

        best_value = node.value

        # if depth == 0  # || terminal node (checkmate)
        #   if value <= alpha
        #     $tt.store(node, depth, :lower_bound, value)  # what is saved for best_node?
        #   elsif value >= beta
        #     $tt.store(node, depth, :upper_bound, value)
        #   else
        #     $tt.store(node, depth, :exact_value, value)
        #   end
        #   return value
        # end

        return best_value if best_value >= beta  # assume 'standing pat' lower bound
        alpha = best_value if best_value > alpha

        best_node = nil
        edge_count = 0
        node.tactical_edges.each do |move|
          edge_count += 1
          child = move.create_position
          result = -quiescence(child, depth-1, -beta, -alpha)
          if result > best_value
            best_value = result 
            best_node = child
          end
          alpha = best_value if best_value > alpha
          break if best_value >= beta
        end

        if edge_count == 0 && node.in_check?
          puts "CHECKMATE"
          return -$INF
          #checkmate for side to move.
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
    end


    # Module helper methods

    def self.select_position(root, algorithm = :iterative_deepening_mtdf)
      reset_counters
      $tt = Application::current_game.tt
      strategy = Strategy.new(root, algorithm)
      # puts "\ndepth | main nodes | quiescence nodes | total  nodes | evaluations | memory access"
      best_node, value = strategy.select_position
      # puts "6 | #{$main_calls} | #{$quiescence_calls} | #{$main_calls+$quiescence_calls} | #{$evaluation_calls} | #{$memory_calls}"
      # puts best_node.board.print
      return best_node
    end 

    def self.reset_counters
      $main_calls, $quiescence_calls, $evaluation_calls, $memory_calls = 0, 0, 0, 0
    end

  end
end



