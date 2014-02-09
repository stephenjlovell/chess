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

module Chess
  module Search # this module defines tree traversal algorithms for move selection.

    PLY_VALUE = 4  # multiplier representing the depth value of 1 ply.  
                   # Used for fractional depth extensions / reductions.

    Performance = Struct.new(:depth, :m_nodes, :q_nodes, :all_nodes, :evals, :memory, :avg_eff_branching)

    def self.iterative_deepening_mtdf
      iterative_deepening(@max_depth/PLY_VALUE) do |guess, d, previous_pv, current_pv|
        mtdf(guess, d, previous_pv, current_pv)
      end
    end

    def self.iterative_deepening_alpha_beta
      iterative_deepening(@max_depth/PLY_VALUE) do |guess, d, previous_pv, current_pv|
        alpha_beta(d, -$INF, $INF, previous_pv, current_pv)
      end
    end

    def self.iterative_deepening(depth)
      guess = @node.value
      puts guess
      best_move, value = nil, -$INF
      total_calls, performance_data = 0, []
      previous_pv, current_pv  = Memory::PVStack.new, Memory::PVStack.new
      (1..depth).each do |d|
        # puts "#{d}"
        previous_total = $quiescence_calls + $main_calls
        Search::reset_counters
        current_pv = Memory::PVStack.new
        best_move, value = yield(guess, d*PLY_VALUE, previous_pv, current_pv)
        total_calls = $main_calls + $quiescence_calls
        branching = previous_total == 0.0 ? total_calls + 0.0 : (total_calls**(1r/d))
        performance_data << Performance.new(d, $main_calls, $quiescence_calls, total_calls, 
                                            $evaluation_calls, $memory_calls, branching)
        guess = value

        previous_pv = current_pv
        if Chess::current_game.clock.time_up?
          puts "evaluation time ran out after depth #{d}"; break
        end
      end
      puts "\n"
      tp performance_data  # print out performance data as a table.
      current_pv.print
      # puts "Average effective branching factor: #{total_calls**(1r/depth)}"

      return best_move, value
    end

    def self.mtdf(g=nil, depth=nil, previous_pv=nil, parent_pv=nil) # incrementally sets the alpha-beta search window and call alpha_beta.
      g ||= alpha_beta(PLY_VALUE, -$INF, +$INF) # do a fixed-depth search for first guess
      depth ||= @max_depth
      upper_bound = $INF
      lower_bound = -$INF
      while lower_bound < upper_bound do
        beta = (g == lower_bound ? g+1 : g)
        current_pv = Memory::PVStack.new
        previous_pv.reset_counter if previous_pv
        best_move, g = alpha_beta(depth, beta-1, beta, previous_pv, current_pv)
        if g < beta then upper_bound = g else lower_bound = g end
      end
      return best_move, g, current_pv
    end

    def self.alpha_beta(depth=nil, alpha=-$INF, beta=$INF, previous_pv=nil, parent_pv=nil)
      depth ||= @max_depth
      parent_pv ||= Memory::PVStack.new

      result, best_value, best_move, mate_possible = -$INF, -$INF, nil, true
      current_pv = Memory::PVStack.new

      pv_move = previous_pv.next_move if previous_pv
      if pv_move
        $main_calls += 1
        mate_possible = false

        MoveGen::make!(@node, pv_move)
        result = -alpha_beta_main(@node, depth-PLY_VALUE, -beta, -alpha, previous_pv, current_pv, true)
        # puts "#{pv_move.print}: #{result}"
        MoveGen::unmake!(@node, pv_move)

        if result > best_value
          best_value = result 
          best_move = pv_move
        end
        if best_value > alpha  # child @node now a PV @node.
          alpha = best_value
          append_pv(parent_pv, current_pv, pv_move)
        end
        if best_value >= beta
          result = $tt.store_result(@max_depth, mate_possible, @node, depth, best_value, alpha, beta, best_move)
          return best_move, result
        end
      end

      entry = $tt.retrieve(@node)
      if entry && entry.depth >= depth
        if entry.type == :exact_value
          return entry.best_move, entry.value  # retrieve PV from entry.pv
        elsif entry.type == :lower_bound && entry.value > alpha
          alpha = entry.value 
        elsif entry.type == :upper_bound && entry.value < beta
          beta = entry.value
        end
        return entry.best_move, entry.value if alpha >= beta # retrieve PV from entry.pv
      end

      @node.edges.each do |move|
        $main_calls += 1
        mate_possible = false

        MoveGen::make!(@node, move)
        extension = PLY_VALUE  # start with a full ply extension.
        # extension -= 1 if move.capture_value >= 1.5
        # extension -= 2 if @node.in_check?
        result = -alpha_beta_main(@node, depth-extension, -beta, -alpha, previous_pv, current_pv)
        # puts "#{move.print}: #{result}"
        MoveGen::unmake!(@node, move)

        if result > best_value
          best_value = result 
          best_move = move
        end
        if best_value > alpha  # child node now a PV node.
          alpha = best_value
          append_pv(parent_pv, current_pv, move)
        end
        break if best_value >= beta
      end
      result = $tt.store_result(@max_depth, mate_possible, @node, depth, best_value, alpha, beta, best_move)
      return best_move, result
    end

    def self.alpha_beta_main(node, depth, alpha=-$INF, beta=$INF, previous_pv=nil, parent_pv=nil, on_pv=false)

      result, best_value, best_move, mate_possible = -$INF, -$INF, nil, true
      current_pv = Memory::PVStack.new
      
      if on_pv  # try the PV move first
        pv_move = previous_pv.next_move
        if pv_move
          mate_possible = false
          
          MoveGen::make!(@node, pv_move)
          result = -alpha_beta_main(@node, depth-PLY_VALUE, -beta, -alpha, previous_pv, current_pv, true)
          MoveGen::unmake!(@node, pv_move)

          if result > best_value
            best_value = result 
            best_move = pv_move
          end
          if best_value > alpha # child node now a PV node.
            alpha = best_value
            append_pv(parent_pv, current_pv, pv_move)
          end
          if best_value >= beta
            return $tt.store_result(@max_depth, mate_possible, @node, depth, best_value, alpha, beta, best_move)
          end
        end
      end
      
      entry = $tt.retrieve(@node)  # then probe the transposition table for a hash move:
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
        mate_possible = @node.edges.count == 0
        best_value = quiescence(@node, depth-PLY_VALUE, alpha, beta) # not making or unmaking here.
        # best_value = @node.value
        return $tt.store_result(@max_depth, mate_possible, @node, 0, best_value, alpha, beta)  
      end

      @node.edges.each do |move|
        $main_calls += 1
        mate_possible = false  # if legal moves are available, it's not checkmate.

        MoveGen::make!(@node, move)
        extension = PLY_VALUE  # start with a full ply extension.
        # extension -= 1 if move.capture_value >= 1.5
        # extension -= 2 if @node.in_check?
        result = -alpha_beta_main(@node, depth-extension, -beta, -alpha, previous_pv, current_pv)
        MoveGen::unmake!(@node, move)

        if result > best_value
          best_value = result 
          best_move = move
        end
        if best_value > alpha # child @node now a PV @node.
          alpha = best_value
          append_pv(parent_pv, current_pv, move)
        end
        break if best_value >= beta
      end

      $tt.store_result(@max_depth, mate_possible, @node, depth, best_value, alpha, beta, best_move)
    end

    def self.quiescence(node, depth, alpha, beta)  # quiesence nodes are not part of the principal variation.

      entry = $tt.retrieve(@node)
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

      best_value = @node.value  # assume 'standing pat' lower bound
      return best_value if best_value >= beta  
      alpha = best_value if best_value > alpha

      result, best_move, see_squares, mate_possible = -$INF, nil, {}, true

      @node.tactical_edges.each do |move|

        see_squares[move.to] ||= Search::get_see_score(@node, move.to) # perform static exchange evaluation
        next if see_squares[move.to] <= 0

        $quiescence_calls += 1
        mate_possible = false

        MoveGen::make!(@node, move)
        result = -quiescence(@node, depth-PLY_VALUE, -beta, -alpha)
        MoveGen::unmake!(@node, move)
        
        if result > best_value
          best_value = result 
          best_move = move
        end
        alpha = best_value if best_value > alpha
        break if best_value >= beta

      end

      $tt.store_result(@max_depth, mate_possible, @node, depth, best_value, alpha, beta, best_move)
    end

    def self.append_pv(parent_pv, current_pv, move)
      parent_pv.clear
      parent_pv[0] = move
      parent_pv += current_pv  # merge PVStack for child node into PVStack for parent @node.
    end

    def self.get_see_score(position, to)
      attackers = position.board.get_square_attackers(to)
      static_exchange_evaluation(position.board, to, position.side_to_move, attackers)
    end

    def self.static_exchange_evaluation(board, to, side, attackers) # Iterative SEE algorithm based on alpha beta pruning.
      score = 0
      alpha, beta = -$INF, $INF
      other_side = FLIP_COLOR[side]

      counters = { w: 0, b: 0 }
      attacker_count = { w: attackers[:w].count, b: attackers[:b].count }

      victim = board[to]
      while true
        score += Pieces::get_value_by_sym(victim)
        # puts score
        return alpha if score <= alpha || counters[side] >= attacker_count[side]  # stand pat 
        
        victim = board[attackers[side][counters[side]]]
        counters[side] += 1
        beta = score if score < beta # beta update
        score -= Pieces::get_value_by_sym(victim)

        return beta if score >= beta || counters[other_side] >= attacker_count[other_side]  # stand pat
        
        victim = board[attackers[other_side][counters[other_side]]]  
        counters[other_side] += 1
        alpha = score if score > alpha  # alpha update
      end
    end

    # Module interface

    def self.reset_counters
      $main_calls, $quiescence_calls, $evaluation_calls, $memory_calls = 0, 0, 0, 0
    end

    def self.select_move(node, max_depth=4)
      @node, @max_depth = node, max_depth * PLY_VALUE  # Use class instance variables rather than class variables.
      reset_counters
      Chess::current_game.clock.restart
      best_move, value = block_given? ? yield : iterative_deepening_alpha_beta # use mtdf by default?
      puts "Eval score: #{value}"
      return best_move
    end 

  end
end



