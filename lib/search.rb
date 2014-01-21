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
  module Search # this module defines tree traversal algorithms for move selection.

    class Strategy
      attr_reader :algorithm

      def initialize(root, max_depth, algorithm = :iterative_deepening_mtdf)
        @root, @max_depth, @algorithm  = root, (max_depth * 4), algorithm
      end

      def select_position
        raise "search algorithm #{@algorithm} is unavailable" unless respond_to?(@algorithm)
        best_node, value = send(@algorithm)
      end

      def iterative_deepening_mtdf
        iterative_deepening(@max_depth/4) do |guess, d, previous_pv, current_pv|
          mtdf(guess, d, previous_pv, current_pv)
        end
      end

      def iterative_deepening_alpha_beta
        iterative_deepening(@max_depth/4) do |guess, d, previous_pv, current_pv|
          alpha_beta(d, -$INF, $INF, previous_pv, current_pv)
        end
      end

      def iterative_deepening(depth)
        guess = @root.parent ? @root.parent.value : @root.value
        best_node = nil
        value = -$INF
        puts "\nd | main | quies. | total | evals | memory | non-replacements"
        previous_pv, current_pv  = Memory::PVStack.new, Memory::PVStack.new
        (1..depth).each do |d|
          Search::reset_counters
          current_pv = Memory::PVStack.new
          best_node, value = yield(guess, d*2, previous_pv, current_pv)
          puts "#{d} |m #{$main_calls} |q #{$quiescence_calls} |t #{$main_calls+$quiescence_calls} |e #{$evaluation_calls} |m #{$memory_calls} |n #{$non_replacements}"
          guess = value
          # current_pv.print
          previous_pv = current_pv
          if Application::current_game.clock.time_up?
            puts "evaluation time ran out after depth #{d}"; break
          end
        end
        current_pv.print
        best_node.board.print
        return best_node, value
      end

      def mtdf(g=nil, depth=nil, previous_pv=nil, parent_pv=nil) # incrementally sets the alpha-beta search window and call alpha_beta.
        g ||= @root.value
        depth ||= @max_depth
        upper_bound = $INF
        lower_bound = -$INF
        while lower_bound < upper_bound do
          beta = (g == lower_bound ? g+1 : g)
          current_pv = Memory::PVStack.new
          previous_pv.reset_counter
          best_node, g = alpha_beta(depth, beta-1, beta, previous_pv, current_pv)
          if g < beta then upper_bound = g else lower_bound = g end
        end
        return best_node, g, current_pv
      end

      def alpha_beta(depth=@max_depth/4, alpha=-$INF, beta=$INF, previous_pv=nil, parent_pv=nil)
        depth ||= @max_depth
        parent_pv ||= Memory::PVStack.new

        entry = $tt.retrieve(@root)
        if entry && entry.depth >= depth
          if entry.type == :exact_value
            return entry.best_node, entry.value  # retrieve PV from entry.pv
          elsif entry.type == :lower_bound && entry.value > alpha
            alpha = entry.value 
          elsif entry.type == :upper_bound && entry.value < beta
            beta = entry.value
          end
          return entry.best_node, entry.value if alpha >= beta # retrieve PV from entry.pv
        end

        best_value, best_node, mate_possible = -$INF, nil, true
        current_pv = Memory::PVStack.new

        pv_move = previous_pv.next_move if previous_pv
        if pv_move
          $main_calls += 1
          mate_possible = false
          child = pv_move.create_position
          result = -alpha_beta_main(child, depth-3, -beta, -alpha, previous_pv, current_pv, true)
          if result > best_value
            best_value = result 
            best_node = child
          end
          if best_value > alpha  # child node now a PV node.
            alpha = best_value
            append_pv(parent_pv, current_pv, pv_move)
          end
        end

        @root.edges.each do |move|
          next if pv_move && move.hash == pv_move.hash
          $main_calls += 1
          mate_possible = false
          child = move.create_position
          extension = 4  # start with a full ply extension.
          extension -= 1 if move.capture_value >= 1.5
          extension -= 2 if child.in_check?
          result = -alpha_beta_main(child, depth-extension, -beta, -alpha, previous_pv, current_pv)
          if result > best_value
            best_value = result 
            best_node = child
          end
          if best_value > alpha  # child node now a PV node.
            alpha = best_value
            append_pv(parent_pv, current_pv, move)
          end
          break if best_value >= beta
        end
        result = $tt.store_result(@root, @max_depth, mate_possible, @root, depth, best_value, alpha, beta, best_node)
        return best_node, result
      end

      def alpha_beta_main(node, depth, alpha=-$INF, beta=$INF, previous_pv=nil, parent_pv=nil, on_pv=false)

        entry = $tt.retrieve(node)
        if entry && entry.depth >= depth
          if entry.type == :exact_value
            return entry.value
          elsif entry.type == :lower_bound && entry.value > alpha
            alpha = entry.value 
          elsif entry.type == :upper_bound && entry.value < beta
            beta = entry.value
          end
          if alpha >= beta
            return entry.value 
          end
        end

        if depth <= 0
          mate_possible = node.edges.count == 0
          best_value = -quiescence(node, -1, -beta, -alpha)
          return $tt.store_result(@root, @max_depth, mate_possible, node, 0, best_value, alpha, beta)  
        end

        best_value, best_node, mate_possible = -$INF, nil, true
        current_pv = Memory::PVStack.new

        if on_pv
          pv_move = previous_pv.next_move
          if pv_move
            mate_possible = false
            child = pv_move.create_position
            result = -alpha_beta_main(child, depth-3, -beta, -alpha, previous_pv, current_pv, true)
            if result > best_value
              best_value = result 
              best_node = child
            end
            if best_value > alpha # child node now a PV node.
              alpha = best_value
              append_pv(parent_pv, current_pv, pv_move)
            end
          end
        end

        # pv_move = previous_pv.next_move
        node.edges.each do |move|
          next if pv_move && move.hash == pv_move.hash
          $main_calls += 1
          mate_possible = false  # if legal moves are available, it's not checkmate.
          child = move.create_position
          extension = 4  # start with a full ply extension.
          extension -= 1 if move.capture_value >= 1.5
          extension -= 2 if child.in_check?
          result = -alpha_beta_main(child, depth-extension, -beta, -alpha, previous_pv, current_pv)
          if result > best_value
            best_value = result 
            best_node = child
          end
          if best_value > alpha # child node now a PV node.
            alpha = best_value
            append_pv(parent_pv, current_pv, move)
          end
          break if best_value >= beta
        end

        $tt.store_result(@root, @max_depth, mate_possible, node, depth, best_value, alpha, beta, best_node)
      end

      def quiescence(node, depth, alpha, beta)  # quiesence nodes are not part of the principal variation.

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

        best_value = node.value  # assume 'standing pat' lower bound
        return best_value if best_value >= beta  
        alpha = best_value if best_value > alpha

        best_node, mate_possible = nil, true

        node.tactical_edges.each do |move|
          $quiescence_calls += 1
          mate_possible = false
          child = move.create_position
          result = -quiescence(child, depth-4, -beta, -alpha)
          if result > best_value
            best_value = result 
            best_node = child
          end
          alpha = best_value if best_value > alpha
          break if best_value >= beta
        end
        $tt.store_result(@root, @max_depth, mate_possible, node, depth, best_value, alpha, beta, best_node)
      end

      def append_pv(parent_pv, current_pv, move)
        parent_pv.clear
        parent_pv[0] = move
        parent_pv += current_pv  # merge PVStack for child node into PVStack for parent node.
      end
    end  # end Strategy class

    # Module helper methods

    def self.select_position(root, algorithm = :iterative_deepening_mtdf, max_depth=5)
      reset_counters
      $tt = Application::current_game.tt
      strategy = Strategy.new(root, max_depth, algorithm)
      best_node, value = strategy.select_position
      return best_node
    end 

    def self.reset_counters
      $main_calls, $quiescence_calls, $evaluation_calls, $memory_calls, $non_replacements = 0, 0, 0, 0, 0
    end

  end
end



