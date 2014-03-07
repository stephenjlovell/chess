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

    MTD_STEP_SIZE = 15

    MTDF_MAX_PASSES = 200  # Prevent infinite feedback loop due to rare TT interactions.

    def self.iterative_deepening_mtdf_step(max_depth=nil)
      max_depth ||= @max_depth
      iterative_deepening(max_depth/PLY_VALUE) do |guess, d|
        mtdf_step(guess, d)
      end
    end

    def self.iterative_deepening_mtdf(max_depth=nil)
      max_depth ||= @max_depth
      iterative_deepening(max_depth/PLY_VALUE) do |guess, d|
        mtdf(guess, d)
      end
    end

    def self.iterative_deepening_alpha_beta(max_depth=nil)
      max_depth ||= @max_depth
      iterative_deepening(max_depth/PLY_VALUE) do |guess, d|
        alpha_beta_root(d, -$INF, $INF)
      end
    end

    def self.iterative_deepening(depth)
      best_move, guess, value = nil, nil, -$INF
      search_records = [] if @verbose
      first_total = 0.0
      (1..depth).each do |d|
        @i_depth = d
        previous_total = $quiescence_calls + $main_calls
        # puts "----#{d}----"
        Search::reset_counters
        best_move, value = yield(guess, d*PLY_VALUE) # call main search algo.
        first_total = $quiescence_calls + $main_calls if d == 1
        record = Analytics::SearchRecord.new(d, value, $passes, $main_calls, $quiescence_calls, 
                                             $evaluation_calls, $memory_calls, previous_total, first_total)
        search_records << record if @verbose
        @aggregator.aggregate(record) unless @aggregator.nil?

        guess = value
        if Chess::current_game.clock.time_up?
          puts "evaluation time ran out after depth #{d}" if @verbose
          break
        end
      end
      if @verbose
        puts "\n"
        tp search_records  # print out performance data as a table.
      end
      return best_move, value
    end

    def self.internal_iterative_deepening_alpha_beta(max_depth=nil)
      max_depth ||= @max_depth
      internal_iterative_deepening(max_depth/PLY_VALUE) do |guess, d|
        alpha_beta_root(d, -$INF, $INF)
      end
    end

    def self.internal_iterative_deepening(depth)
      best_move, guess, value = nil, nil, -$INF
      (1..depth).each do |d|
        best_move, value = yield(guess, d*PLY_VALUE) # call main search algo.
        guess = value
      end
      return best_move, value
    end

    def self.get_initial_estimate
      if @node.in_check?
        puts "check"
        move, value = internal_iterative_deepening_alpha_beta(2*PLY_VALUE)
      else
        value, count = quiescence(0)
      end
      return value
    end


    def self.mtdf(guess=nil, depth=nil) 
      guess ||= (@previous_value || get_initial_estimate)
      depth ||= @max_depth
      best, @lower_bound, @upper_bound, mtdf_passes = -$INF, -$INF, $INF, 0

      while @lower_bound < @upper_bound && mtdf_passes < MTDF_MAX_PASSES
        $passes += 1
        mtdf_passes += 1

        # puts "max passes reached" if mtdf_passes >= MTDF_MAX_PASSES

        gamma = guess == @lower_bound ? guess+1 : guess

        move, guess = alpha_beta_root(depth, gamma-1, gamma)
        best_move, best = move, guess unless move.nil?        
        # puts "#{mtdf_passes} MT(#{depth}, #{gamma-1}, #{gamma}) => #{move}, #{guess}"

        guess < gamma ? @upper_bound = guess : @lower_bound = guess
      end
      return best_move, best
    end


    def self.mtdf_step(guess=nil, depth=nil) # MTD-f with "convergence accelerator"
      guess ||= (@previous_value || get_initial_estimate)
      depth ||= @max_depth
      mtdf_passes, best, @lower_bound, @upper_bound, step = 0, -$INF, -$INF, $INF, MTD_STEP_SIZE
      stepped_up, stepped_down = false, false

      while @lower_bound < @upper_bound && mtdf_passes < MTDF_MAX_PASSES
        $passes += 1
        mtdf_passes += 1

        gamma = guess == @lower_bound ? guess+1 : guess
        move, guess = alpha_beta_root(depth, gamma-1, gamma)
        best_move, best = move, guess unless move.nil?
        # return best_move, guess if Chess::current_game.clock.time_up?

        if guess < gamma
          @upper_bound = guess
          guess = max(guess-step, @lower_bound+1)
          stepped_down = true
        else
          @lower_bound = guess
          guess = min(guess+step, @upper_bound-1)
          stepped_up = true
        end

        if stepped_up && stepped_down
          step /= 2
        elsif step < (@upper_bound - @lower_bound)/2
          step *= 2 
        end

        guess += @upper_bound == guess ? -step : step
        guess = @upper_bound if @upper_bound < guess
        guess = @lower_bound if @lower_bound > guess
      end

      return best_move, best
    end


    def self.alpha_beta_root(depth=nil, alpha=-$INF, beta=$INF)
      depth ||= @max_depth
      sum, result, best_move, legal_moves, first_moves = 1, -$INF, nil, false, []

      $tt.get_hash_move(@node, first_moves) # At root, use TT for move ordering only.

      in_check = @node.in_check?
      ext_check = in_check ? EXT_CHECK : 0

      @node.edges(first_moves, true).each do |move| 
        next unless @node.avoids_check?(move)  # no illegal moves allowed at root.

        $main_calls += 1
        
        MoveGen::make!(@node, move)
        value, count = alpha_beta(depth-PLY_VALUE+ext_check, -beta, -alpha)
        MoveGen::unmake!(@node, move)
        result = max(-value, result)
        sum += count
        legal_moves = true unless result <= Pieces::KING_LOSS

        if result > alpha
          alpha = result
          best_move = move
          break if result >= beta
        end  
      end

      unless legal_moves  # if no legal moves available, it's either a draw or checkmate.
        result = in_check ? (@i_depth*PLY_VALUE - depth) - Pieces::MATE : 0 # mate in 1 is more valuable than mate in 2
        best_move = nil
      end

      $tt.store_result(@node, depth, sum, result, alpha, beta, best_move)
      return best_move, result
    end

    def self.alpha_beta(depth, alpha=-$INF, beta=$INF, can_null=true)
      first_moves, result, best_move = [], -$INF, nil

      return quiescence(depth, alpha, beta) if depth <= 0 # not making or unmaking here.

      if $tt.ok?(@node)  # probe the hash table for @node
        $memory_calls += 1
        e = $tt.get(@node)
        unless e.nil?
          first_moves << e.move unless e.move.nil?
          if e.depth >= depth
            return e.alpha, e.count if e.alpha >= beta
            return e.beta, e.count if e.beta <= alpha
            # alpha = max(alpha, e.alpha)
            # beta = min(beta, e.beta)
          end
        end
      end

      in_check = @node.in_check?
      ext_check = in_check ? EXT_CHECK : 0

      # ideally null-move pruning should not be performed on PV nodes.

      # Null Move Pruning
      if can_null && !in_check && depth > 2*PLY_VALUE && !@node.in_endgame? && @node.value >= beta
        enp, reduction = @node.enp_target, 2*PLY_VALUE
        MoveGen::flip_null(@node, enp)
        @node.enp_target = nil
        value, count = alpha_beta(depth-PLY_VALUE-reduction, -beta, -beta+1, false) 
        value *= -1       
        MoveGen::flip_null(@node, enp)
        @node.enp_target = enp

        return value, count if value >= beta
      end

      moves = @node.edges(first_moves)

      # Enhanced Transposition Cutoffs
      if depth >= 2*PLY_VALUE
        moves.each do |move|
          e = nil
          MoveGen::make!(@node, move)
          e = $tt.get(@node) if $tt.ok?(@node)  # probe the hash table for node
          MoveGen::unmake!(@node, move)
          if !e.nil? && e.depth >= depth
            return e.alpha, e.count if e.alpha >= beta
            return e.beta, e.count if e.beta <= alpha
          end
        end
      end

      # Extended futility pruning:
      f_margin = depth > PLY_VALUE ? Pieces::PIECE_VALUES[:R] : Pieces::PIECE_VALUES[:N]
      f_prune = depth <= 2*PLY_VALUE && !in_check && alpha.abs < Pieces::MATE &&
                @node.value + f_margin <= alpha

      sum, legal_moves = 1, false
      moves.each do |move|
        
        MoveGen::make!(@node, move)
        if f_prune && legal_moves && !move.material_swing? && !@node.in_check? # when f_prune flag is set,
          MoveGen::unmake!(@node, move) # prune moves that don't alter material balance or give check.
          next
        end
        value, count = alpha_beta(depth-PLY_VALUE+ext_check, -beta, -alpha)
        MoveGen::unmake!(@node, move)

        $main_calls += 1
        result = max(-value, result)
        sum += count
        legal_moves = true unless result <= Pieces::KING_LOSS

        if result > alpha
          alpha = result
          best_move = move
          break if result >= beta
        end  
      end

      unless legal_moves  # if no legal moves available, it's either a draw or checkmate.
        result = in_check ? -(Pieces::MATE + @i_depth - depth/PLY_VALUE) : 0 # mate in 1 is more valuable than mate in 2
      end

      $tt.store_result(@node, depth, sum, result, alpha, beta, best_move)
    end


    def self.quiescence(depth, alpha=-$INF, beta=$INF)  # quiesence nodes are not part of the principal variation.
      result, best_move, first_moves = -$INF, nil, []

      if $tt.ok?(@node)  # probe the hash table for @node
        $memory_calls += 1
        e = $tt.get(@node)
        unless e.nil?
          first_moves << e.move unless e.move.nil?
          if e.depth >= depth
            return e.alpha, e.count if e.alpha >= beta
            return e.beta, e.count if e.beta <= alpha
            # alpha = max(alpha, e.alpha)
            # beta = min(beta, e.beta)
          end
        end
      end

      result = @node.value  # assume 'standing pat' lower bound
      return beta, 1 if result >= beta # fail hard beta cutoff
      alpha = result if result > alpha

      sum = 1
      @node.tactical_edges(first_moves).each do |move|
        next if move.see && move.see < 0  # moves are ordered by SEE

        MoveGen::make!(@node, move)
        value, count = quiescence(depth-PLY_VALUE, -beta, -alpha)
        MoveGen::unmake!(@node, move)

        $quiescence_calls += 1
        result = max(-value, result)
        sum += count

        if result > alpha
          alpha = result
          best_move = move
          break if result >= beta
        end        
      end

      $tt.store_result(@node, depth, sum, result, alpha, beta, best_move)
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

    def self.max(x,y)
      x > y ? x : y
    end

    def self.min(x,y)
      x < y ? x : y
    end

    def self.get_pv(node)
      pv, key = [], node.hash
      until !$tt.key_ok?(key) || $tt[key].move.nil?
        pv << $tt[key].move
        key ^= e.move.hash ^ Memory::side_key
      end
    end

    # Module interface

    def self.reset_counters
      $main_calls, $quiescence_calls, $evaluation_calls, $memory_calls, $passes = 0, 0, 0, 0, 0
    end

    def self.select_move(node, max_depth=5, aggregator=nil, verbose=true)
      Chess::current_game.clock.restart
      @node, @max_depth, @aggregator, @verbose = node, max_depth*PLY_VALUE, aggregator, verbose
      @previous_value = Chess::current_game.previous_value || nil
      
      reset_counters
      # $tt.clear  # clear the transposition table.  At TT sizes above 500k, lookup times begin to 
      #            # outweigh benefit of additional entries.

      move, value = block_given? ? yield : iterative_deepening_mtdf # use mtdf by default?

      if @verbose && !move.nil? 
        puts "Move chosen: #{move.print}, Score: #{value}, TT size: #{$tt.size}"
      end 
      return move, value
    end 

  end
end



