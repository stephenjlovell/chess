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
    
    EXT_CHECK = 1  # extend search when side to move is in check.

    EXT_PV = 1     # extend search when on the principal variation from previous iterative deepening.

    MTD_STEP_SIZE = 5 # 

    def self.iterative_deepening_mtdf_step(max_depth=nil)
      @mtdf = true
      depth = max_depth || @max_depth
      iterative_deepening(@max_depth/PLY_VALUE) do |guess, d, previous_pv, current_pv|
        mtdf_step(guess, d, previous_pv, current_pv)
      end
    end

    def self.iterative_deepening_mtdf(max_depth=nil)
      @mtdf = true
      depth = max_depth || @max_depth
      iterative_deepening(@max_depth/PLY_VALUE) do |guess, d, previous_pv, current_pv|
        mtdf(guess, d, previous_pv, current_pv)
      end
    end

    def self.iterative_deepening_alpha_beta(max_depth=nil)
      @mtdf = false
      depth = max_depth || @max_depth
      iterative_deepening(depth/PLY_VALUE) do |guess, d, previous_pv, current_pv|
        alpha_beta_root(d, -$INF, $INF, previous_pv, current_pv)
      end
    end

    def self.iterative_deepening(depth)
      guess = @previous_value || @node.value
      best_move, value = nil, -$INF
      search_records = [] if @verbose
      previous_pv, current_pv  = Memory::PVStack.new, Memory::PVStack.new
      (1..depth).each do |d|
        @i_depth = d
        previous_total = $quiescence_calls + $main_calls
        Search::reset_counters
        current_pv = Memory::PVStack.new
        # puts d
        best_move, value = yield(guess, d*PLY_VALUE, previous_pv, current_pv) # call main search algo.
        
        record = Analytics::SearchRecord.new(d, value, $mtdf_ct, $main_calls, $quiescence_calls, 
                                             $evaluation_calls, $memory_calls, previous_total)
        search_records << record if @verbose
        @aggregator.aggregate(record) unless @aggregator.nil?

        guess = value
        previous_pv = current_pv
        if Chess::current_game.clock.time_up?
          puts "evaluation time ran out after depth #{d}" if @verbose
          break
        end
      end
      if @verbose
        puts "\n"
        tp search_records  # print out performance data as a table.
        current_pv.print
      end
      return best_move, value
    end

    # def self.internal_iterative_deepening(depth)
    #   guess = @previous_value || @node.value
    #   depth /= PLY_VALUE
    #   best_move, value, total_calls = nil, -$INF, 0.0
    #   previous_pv, current_pv  = Memory::PVStack.new, Memory::PVStack.new
    #   (1..depth).each do |d|
    #     current_pv = Memory::PVStack.new
    #     best_move, value = alpha_beta_root(d*PLY_VALUE, -$INF, $INF, previous_pv, current_pv)
    #     # best_move, value = mtdf_step(guess, d*PLY_VALUE, previous_pv, current_pv)
    #     previous_pv = current_pv
    #   end
    #   return best_move, value
    # end

    def self.mtdf(f=nil, depth=nil, previous_pv=nil, parent_pv=nil) 
      f = @previous_value || @node.value
      depth ||= @max_depth
      @lower_bound, @upper_bound = -$INF, $INF
      while @lower_bound < @upper_bound do
        $mtdf_ct += 1
        r = f == @lower_bound ? f+1 : f
        current_pv = Memory::PVStack.new
        previous_pv.reset_counter if previous_pv
        best_move, f = alpha_beta_root(depth, r-1, r, previous_pv, current_pv)
        
        return nil, -$INF if best_move == nil # prevent infinite loop on checkmate
        return best_move, f if Chess::current_game.clock.time_up?

        if f < r then @upper_bound = f else @lower_bound = f end
      end
      return best_move, f
    end

    def self.mtdf_step(f=nil, depth=nil, previous_pv=nil, parent_pv=nil) # MTD-f with "convergence accelerator"
      f ||= @previous_value || @node.value 
      depth ||= @max_depth
      @lower_bound, @upper_bound, step = -$INF, $INF, MTD_STEP_SIZE
      stepped_up, stepped_down = false, false

      while @lower_bound != @upper_bound do
        $mtdf_ct += 1
        r = f == @lower_bound ? f+1 : f
        current_pv = Memory::PVStack.new
        previous_pv.reset_counter if previous_pv
        # puts "step: #{step} lower: #{@lower_bound}, upper: #{@upper_bound}"
        # puts "alpha_beta_root(#{depth}, #{r-1}, #{r}, #{previous_pv}, #{current_pv})"
        best_move, f = alpha_beta_root(depth, r-1, r, previous_pv, current_pv)
        
        return nil, -$INF if best_move.nil?  # prevent infinite loop on checkmate
        return best_move, f if Chess::current_game.clock.time_up?

        if f < r 
          @upper_bound = f
          f = max(f-step, @lower_bound+1)
          stepped_down = true
        else
          @lower_bound = f
          f = min(f+step, @upper_bound+1)
          stepped_up = true
        end

        if stepped_up && stepped_down
          step /= 2
        else
          step *= 2 if step < (@upper_bound - @lower_bound)/2
        end

        f += @upper_bound == f ? -step : step

        f = @upper_bound if @upper_bound < f
        f = @lower_bound if @lower_bound > f
      end
      return best_move, f
    end


    def self.max(x,y)
      x > y ? x : y
    end

    def self.min(x,y)
      x < y ? x : y
    end

    def self.alpha_beta_root(depth=nil, alpha=-$INF, beta=$INF, previous_pv=nil, parent_pv=nil)
      depth ||= @max_depth
      parent_pv ||= Memory::PVStack.new
      current_pv = Memory::PVStack.new
      result, best_value, best_move, first_moves = -$INF, -$INF, nil, []

      # if available, use the PV move from previous iterative deepening first.
      pv_move = previous_pv.next_move if previous_pv
      first_moves << pv_move unless pv_move.nil?
      
      # allow use of hash move for ordering at root, but not to truncate search.
      $tt.probe(@node, depth, alpha, beta, first_moves)

      @node.edges(true, first_moves).each do |move|

        $main_calls += 1

        next unless @node.avoids_check?(move)  # no illegal moves allowed at root.

        MoveGen::make!(@node, move)
        result = -alpha_beta(@node, depth-PLY_VALUE, -beta, -alpha, previous_pv, current_pv)
        MoveGen::unmake!(@node, move)
        
        # puts "#{move.print}: #{result}"

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


      result = $tt.flag_and_store(@node, depth, best_value, alpha, beta, best_move)
      return best_move, result
    end

    def self.alpha_beta(node, depth, alpha=-$INF, beta=$INF, previous_pv=nil, parent_pv=nil, on_pv=false, can_null=true)

      if depth <= 0
        best_value = quiescence(@node, depth, alpha, beta) # not making or unmaking here.
        return $tt.flag_and_store(@node, depth, best_value, alpha, beta)  
      end

      result, best_value, best_move = -$INF, -$INF, nil
      current_pv, first_moves = Memory::PVStack.new, []

      in_check = @node.in_check?
      ext_check = in_check ? EXT_CHECK : 0


      if on_pv  # try the PV move first
        pv_move = previous_pv.next_move
        first_moves << pv_move if pv_move
      end

      hash_value = $tt.probe(@node, depth, alpha, beta, first_moves)  # then try probing the hash table for a first move.
      return hash_value unless hash_value.nil?

      # if no move available from PV or memory, use IID to get a decent first move.

      # if first_moves.empty? && depth >= @iid_minimum # only called at high depth where cost/benefit is more favorable.
      #   # puts "internal iterative deepening"
      #   iid_move, result = internal_iterative_deepening(depth/2)
      #   first_moves << iid_move unless iid_move.nil?
      # end

      # Null Move Pruning
      if depth > 2*PLY_VALUE && can_null && @node.value > beta && !@node.in_endgame? && !in_check
        # puts "null move pruning"
        enp = @node.enp_target
        MoveGen::flip_null(@node, enp)
        @node.enp_target = nil

        # reduction = depth > 5*PLY_VALUE ? 4*PLY_VALUE : 3*PLY_VALUE
        reduction = depth/2*PLY_VALUE
        result = -alpha_beta(@node, depth-reduction, -beta, -beta+1, previous_pv, current_pv, false, false)        

        MoveGen::flip_null(@node, enp)
        @node.enp_target = enp

        if result >= beta
          return beta
        end 
      end

      # before looping over moves, get applicable killer moves.

      legal_moves = false
      @node.edges(on_pv, first_moves).each do |move|  # expend additional move ordering effort when at PV nodes.
        $main_calls += 1

        MoveGen::make!(@node, move)
        result = -alpha_beta(@node, depth-PLY_VALUE+ext_check, -beta, -alpha, previous_pv, current_pv)
        MoveGen::unmake!(@node, move)

        legal_moves = true unless result <= Pieces::KING_LOSS

        if result > best_value
          best_value = result 
          best_move = move
        end
        if best_value > alpha # child node is part of pv.
          alpha = best_value
          append_pv(parent_pv, current_pv, move)
        end
        break if best_value >= beta
      end

      unless legal_moves  # if no legal moves available, it's either a draw or checkmate.
        best_value = in_check ? -(Pieces::MATE + @i_depth - depth/PLY_VALUE) : 0 # mate in 1 is more valuable than mate in 2
        return $tt.store(@node, @max_depth, :exact_value, best_value, nil) 
      end

      $tt.flag_and_store(@node, depth, best_value, alpha, beta, best_move)
    end

    def self.quiescence(node, depth, alpha, beta)  # quiesence nodes are not part of the principal variation.

      hash_value = $tt.probe(@node, depth, alpha, beta)
      return hash_value unless hash_value.nil?

      best_value = @node.value  # assume 'standing pat' lower bound
      return best_value if best_value >= beta  
      alpha = best_value if best_value > alpha

      result, best_move = -$INF, nil

      @node.tactical_edges.each do |move|

        next if move.see && move.see < 0  # moves are ordered by SEE

        $quiescence_calls += 1

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

      $tt.flag_and_store(@node, depth, best_value, alpha, beta, best_move)
    end

    def self.append_pv(parent_pv, current_pv, move)
      parent_pv.clear
      parent_pv[0] = move
      parent_pv += current_pv  # merge child node PV into parent node PV.
    end

    def self.get_see_score(position, to)
      attackers = position.board.get_square_attackers(to)
      static_exchange_evaluation(position.board, to, position.side_to_move, attackers)
    end

    def self.static_exchange_evaluation(board, to, side, attackers) # Iterative SEE algo based on alpha beta pruning.
      score = 0
      alpha, beta = -$INF, $INF
      other_side = FLIP_COLOR[side]

      counters = { w: 0, b: 0 }
      attacker_count = { w: attackers[:w].count, b: attackers[:b].count }

      victim = board[to]
      while true
        score += Pieces::get_value_by_sym(victim)
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
      $main_calls, $quiescence_calls, $evaluation_calls, $memory_calls, $mtdf_ct = 0, 0, 0, 0, 0
    end

    def self.select_move(node, max_depth=6, aggregator=nil, verbose=true)
      # Use class instance variables rather than class variables.
      @node, @max_depth, @aggregator, @verbose = node, max_depth * PLY_VALUE, aggregator, verbose
      @iid_minimum = @max_depth-PLY_VALUE*3 > PLY_VALUE*3 ? @max_depth-PLY_VALUE*2 : PLY_VALUE*4
      reset_counters
      Chess::current_game.clock.restart
      @previous_value = Chess::current_game.previous_value
      $tt.clear  # clear the transposition table.  At TT sizes above 500k, lookup times begin to outweigh benefit of 
                 # additional entries.
      move, value = block_given? ? yield : iterative_deepening_alpha_beta # use mtdf by default?

      if @verbose && !move.nil? 
        puts "TT size: #{$tt.size}"
        puts "Move selected: #{move.print}, Eval score: #{value}"
      end 
      return move, value
    end 

  end
end



