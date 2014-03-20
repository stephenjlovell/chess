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

require './lib/pieces.rb'
require './lib/evaluation.rb'

module Chess
  module Search # this module defines tree traversal algorithms for move selection.

    PLY_VALUE = 2  # Multiplier representing the depth value of 1 ply.  
                   # Used for fractional depth extensions / reductions.

    TWO_PLY = 2*PLY_VALUE
    THREE_PLY = 3*PLY_VALUE
    FOUR_PLY = 4*PLY_VALUE

    EXT_CHECK = 1  # Used to extend search by a fraction of a ply when side to move is in check.

    EXT_MAX = TWO_PLY # Maximum number of check extensions permitted.

    MTD_STEP_SIZE = 1 # Initial value used by MTD(f)-Step to adjust bounds and window size.

    MTDF_MAX_PASSES = 50 # Used to prevent feedback loop due to rare TT interactions.

    MATE = Pieces::MATE/Evaluation::EVAL_GRAIN

    KING_LOSS = Pieces::KING_LOSS/Evaluation::EVAL_GRAIN
    
    F_MARGIN_HIGH = Pieces::PIECE_VALUES[:R]/Evaluation::EVAL_GRAIN    
    F_MARGIN_LOW  = Pieces::PIECE_VALUES[:N]/Evaluation::EVAL_GRAIN

    # Calls the MTD(f)-Step algorithm from within an iterative deepening framework.
    def self.iterative_deepening_mtdf_step(max_depth=nil)
      max_depth ||= @max_depth
      iterative_deepening(max_depth/PLY_VALUE) do |guess, d|
        mtdf_step(guess, d)
      end
    end
    # Calls the MTD(f) algorithm from within an iterative deepening framework.
    def self.iterative_deepening_mtdf(max_depth=nil)
      max_depth ||= @max_depth
      iterative_deepening(max_depth/PLY_VALUE) do |guess, d|
        mtdf(guess, d)
      end
    end
    # Calls the Alpha Beta With Memory algorithm from within an iterative deepening framework.
    def self.iterative_deepening_alpha_beta(max_depth=nil)
      max_depth ||= @max_depth
      iterative_deepening(max_depth/PLY_VALUE) do |guess, d|
        alpha_beta_root(d, -$INF, $INF)
      end
    end

    #  Iterative Deepening (ID) repeatedly calls the main search algorithm at increasing maximum depth.
    #     
    #  1. Provides a way to inexpensively gain information early in the search that can be re-used to make 
    #     deeper searching more efficient. Best move information is saved in the Transposition Table (TT). This 
    #     allows the previous best move to be tried first in later search iterations, improving the move ordering
    #     and causing more alpha/beta cutoffs. 
    #  2. The search result from the previous ID iteration can be used to approximate the final result. MTD(f) uses
    #     this info to provide bounds close to the true value, reducing the total number of passes before converging
    #     on the 'exact' minimax value.
    #  3. The result from the previous ID iteration can be returned when a time limit is reached, allowing the search
    #     to be cut off cleanly without risk of serious tactical blunders.

    def self.iterative_deepening(depth)
      best_move, guess, value = nil, nil, -$INF
      search_records = [] if @verbose
      first_total = 0.0
      (1..depth).each do |d|
        @i_depth = d
        previous_total = $quiescence_calls + $main_calls
        Search::reset_counters

        best_move, value = yield(guess, d*PLY_VALUE) # call main search algo.
        
        # Save some performance data about the search.
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
        tp search_records  # Print out performance data as a table when in verbose mode.
      end
      return best_move, value
    end

    # Calls the Alpha Beta With Memory algorithm from within an ID framework, with the specified bounds.
    def self.internal_iterative_deepening_alpha_beta(max_depth=nil, alpha=-$INF, beta=$INF, extension=0)
      max_depth ||= @max_depth
      internal_iterative_deepening(max_depth/PLY_VALUE) do |guess, d|
        alpha_beta_root(d, alpha, beta, extension)
      end
    end

    # At interior nodes, when a best move is not available from the TT, Internal Iterative Deepening (IID) can
    # be called at reduced search depth to get a reasonable guess at the best move to try first.
    def self.internal_iterative_deepening(depth)
      best_move, guess, value = nil, nil, -$INF
      (1..depth).each do |d|
        best_move, value = yield(guess, d*PLY_VALUE) # call main search algo.
        guess = value
      end
      return best_move, value
    end

    # Make an initial guess at the heuristic value of the root node. Used in MTD(f) when no estimate from a previous
    # search or from the previous ID iteration is available.
    def self.get_initial_estimate
      if @node.in_check?
        move, value = alpha_beta_root(PLY_VALUE)
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

        gamma = guess == @lower_bound ? guess+1 : guess
        move, guess = alpha_beta_root(depth, gamma-1, gamma)
        best_move, best = move, guess unless move.nil?

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

        gamma = guess == @lower_bound ? guess+step : guess
        move, guess = alpha_beta_root(depth, gamma-step, gamma)
        best_move, best = move, guess unless move.nil?

        if guess < gamma
          @upper_bound = guess
          guess = Chess::max(guess-step, @lower_bound+1)
          stepped_down = true
        else
          @lower_bound = guess
          guess = Chess::min(guess+step, @upper_bound-1)
          stepped_up = true
        end
        if stepped_up && stepped_down
          step /= 2
        elsif step < (@upper_bound - @lower_bound)/2
          step *= 2 
        end
      
      end
      return best_move, best
    end


    def self.alpha_beta_root(depth=nil, alpha=-$INF, beta=$INF, extension=0)
      depth ||= @max_depth
      sum, result, best_move, legal_moves = 1, -$INF, nil, false

      hash_move = $tt.get_hash_move(@node) # At root, use TT for move ordering only.

      in_check = @node.in_check?
      extension += EXT_CHECK if in_check && extension < EXT_MAX
      adjusted_depth = depth + (extension/PLY_VALUE)*PLY_VALUE # Number of ply remaining until q-search


      # Try the hash move separately first.  If hash move causes a beta cutoff, this saves the effort that would 
      # normally be expended on move generation and sorting.
      unless hash_move.nil? # hash move legality is checked by TT.
        $main_calls += 1
        
        MoveGen::make!(@node, hash_move)
        value, count = alpha_beta(depth-PLY_VALUE, -beta, -alpha, extension)
        MoveGen::unmake!(@node, hash_move)
        result = Chess::max(-value, result)
        sum += count
        legal_moves = true unless result <= KING_LOSS

        if result > alpha
          alpha = result
          best_move = hash_move
          if result >= beta
            store_cutoff(hash_move, adjusted_depth, count)
            $tt.store(@node, adjusted_depth, sum, result, alpha, beta, hash_move)
            return hash_move, result
          end
        end  
      end

      @node.edges(adjusted_depth, true).each do |move| 
        next unless @node.avoids_check?(move)  # no illegal moves allowed at root.
        $main_calls += 1
        
        MoveGen::make!(@node, move)
        value, count = alpha_beta(depth-PLY_VALUE, -beta, -alpha, extension)
        MoveGen::unmake!(@node, move)
        result = Chess::max(-value, result)
        sum += count
        legal_moves = true unless result <= KING_LOSS

        if result > alpha
          alpha = result
          best_move = move
          if result >= beta
            store_cutoff(move, adjusted_depth, count)
            break
          end
        end  
      end

      unless legal_moves  # if no legal moves available, it's either a draw or checkmate.
        result = in_check ? -(MATE + @i_depth - adjusted_depth/PLY_VALUE) : 0 # mate in 1 is more valuable than mate in 2
        best_move = nil
      end

      $tt.store(@node, adjusted_depth, sum, result, alpha, beta, best_move)
      return best_move, result
    end

    def self.alpha_beta(depth, alpha=-$INF, beta=$INF, extension=0, can_null=true)
      result, best_move = -$INF, nil

      return quiescence(0, alpha, beta) if depth+extension < PLY_VALUE

      in_check = @node.in_check?
      extension += EXT_CHECK if in_check && extension < EXT_MAX
      adjusted_depth = depth + (extension/PLY_VALUE)*PLY_VALUE # Number of ply remaining until q-search

      hash_move, hash_value, hash_count = $tt.probe(@node, adjusted_depth, alpha, beta)
      return hash_value, hash_count unless hash_value.nil?

      # Null Move Pruning
      if can_null && !in_check && adjusted_depth > TWO_PLY && !@node.in_endgame? && @node.value >= beta
        enp, reduction = @node.enp_target, TWO_PLY
        MoveGen::flip_null(@node, enp)
        @node.enp_target = nil
        value, count = alpha_beta(depth-PLY_VALUE-reduction, -beta, -beta+1, extension, false)
        value *= -1       
        MoveGen::flip_null(@node, enp)
        @node.enp_target = enp

        if value >= beta
          $tt.store(@node, adjusted_depth, count, value, alpha, beta, nil)
          return value, count 
        end
      end

      # # Enhanced Transposition Cutoffs
      # if adjusted_depth >= THREE_PLY
      #   etc_depth = adjusted_depth-PLY_VALUE
      #   moves = @node.edges(adjusted_depth, adjusted_depth >= FOUR_PLY)
      #   moves.each do |move|
      #     MoveGen::make!(@node, move)
      #     m, value, count = $tt.probe(@node, etc_depth, alpha, beta)
      #     MoveGen::unmake!(@node, move)
      #     return value, count unless value.nil? 
      #   end
      # end

      # # Alternative ETC implementation - hash key update only.
      # if depth > THREE_PLY
      #   moves = @node.edges(adjusted_depth, adjusted_depth >= FOUR_PLY)
      #   moves.each do |move|
      #     hash_value, hash_count = $tt.etc_probe(@node.hash^move.hash, adjusted_depth, alpha, beta)
      #     return hash_value, hash_count unless hash_value.nil?
      #   end
      # end

      # # Internal Iterative deepening
      # if first_moves.empty? && depth >= @iid_minimum
      #   reduction = THREE_PLY
      #   best_move, value = internal_iterative_deepening_alpha_beta(depth-reduction, @lower_bound, @upper_bound, extension)
      #   moves.insert(0, best_move) unless best_move.nil? || !@node.avoids_check?(best_move)
      # end

      sum, legal_moves = 1, false

      unless hash_move.nil?
        $main_calls += 1

        MoveGen::make!(@node, hash_move)
        value, count = alpha_beta(depth-PLY_VALUE, -beta, -alpha, extension)
        MoveGen::unmake!(@node, hash_move)

        result = Chess::max(-value, result)
        sum += count
        legal_moves = true unless result <= KING_LOSS

        if result > alpha
          alpha = result
          best_move = hash_move
          if result >= beta
            store_cutoff(hash_move, adjusted_depth, count)
            return $tt.store(@node, adjusted_depth, sum, result, alpha, beta, hash_move)
          end
        end  
      end

      # Extended futility pruning:
      f_margin = adjusted_depth > PLY_VALUE ? F_MARGIN_HIGH : F_MARGIN_LOW
      f_prune = (adjusted_depth <= TWO_PLY) && !in_check && (alpha.abs < MATE) && (@node.value + f_margin <= alpha)
      moves ||= @node.edges(adjusted_depth, adjusted_depth >= FOUR_PLY)

      moves.each do |move|
        MoveGen::make!(@node, move)
        if f_prune && legal_moves && move.quiet? && !@node.in_check? # When f_prune flag is set,
          MoveGen::unmake!(@node, move)     # prune moves that don't alter material balance or give check.
          next
        end
        value, count = alpha_beta(depth-PLY_VALUE, -beta, -alpha, extension)
        MoveGen::unmake!(@node, move)

        $main_calls += 1
        result = Chess::max(-value, result)
        sum += count
        legal_moves = true unless result <= KING_LOSS

        if result > alpha
          alpha = result
          best_move = move
          if result >= beta
            store_cutoff(move, adjusted_depth, count)
            break
          end
        end  
      end

      unless legal_moves  # if no legal moves available, it's either a draw or checkmate.
        result = in_check ? -(MATE + @i_depth - adjusted_depth/PLY_VALUE) : 0 # mate in 1 is more valuable than mate in 2
      end

      $tt.store(@node, adjusted_depth, sum, result, alpha, beta, best_move)
    end

    def self.store_cutoff(move, depth, nodecount)
      # If the move that caused the cutoff is a 'quiet' move (i.e. not a capture or promotion), then
      # store the move in the Killer Moves table.
      $killer.store(@node, move, depth)
      $history.store(move, nodecount)
    end

    # Depth minimax  
    # Quiescence Search (q-search) is called at leaf nodes when depth is less than one full ply.
    #

    def self.quiescence(depth, alpha=-$INF, beta=$INF)  # quiesence nodes are not part of the principal variation.
      result, best_move, sum = -$INF, nil, 1

      hash_move, hash_value, hash_count = $tt.probe(@node, depth, alpha, beta)
      return hash_value, hash_count unless hash_value.nil?

      result = @node.value  # assume 'standing pat' lower bound
      return beta, sum if result >= beta # fail hard beta cutoff
      alpha = result if result > alpha

      unless hash_move.nil?
        $quiescence_calls += 1

        MoveGen::make!(@node, hash_move)
        value, count = quiescence(depth-PLY_VALUE, -beta, -alpha)
        MoveGen::unmake!(@node, hash_move)

        result = Chess::max(-value, result)
        sum += count

        if result > alpha
          alpha = result
          best_move = hash_move
          if result >= beta
            return $tt.store(@node, depth, sum, result, alpha, beta, best_move)
          end
        end     
      end


      @node.tactical_edges.each do |move|
        next if move.see && move.see < 0  # moves are ordered by SEE
        $quiescence_calls += 1

        MoveGen::make!(@node, move)
        value, count = quiescence(depth-PLY_VALUE, -beta, -alpha)
        MoveGen::unmake!(@node, move)


        result = Chess::max(-value, result)
        sum += count

        if result > alpha
          alpha = result
          best_move = move
          break if result >= beta
        end        
      end

      $tt.store(@node, depth, sum, result, alpha, beta, best_move)
    end

    #  The Static Exchange Evaluation (SEE) heuristic provides a way to determine if a capture 
    #  is a 'winning' or 'losing' capture.
    #
    #  1. When a capture results in an exchange of pieces by both sides, SEE is used to determine the 
    #     net gain/loss in material for the side initiating the exchange.
    #  2. SEE scoring of moves is used for move ordering of captures at critical nodes.
    #  3. During quiescence search, SEE is used to prune losing captures. This provides a very low-risk
    #     way of reducing the size of the q-search without impacting playing strength.

    # This iterative SEE implementation uses alpha beta pruning as proposed by H.G. Muller here:
    # http://www.talkchess.com/forum/viewtopic.php?topic_view=threads&p=310782&t=30905
    def self.see(position, to) 
      board = position.board
      attackers = board.get_square_attackers(to)
      alpha, beta, score, own_counter, enemy_counter = -$INF, $INF, 0, 0, 0
      own, enemy = position.side_to_move, position.enemy
      own_attackers, enemy_attackers = attackers[own].count, attackers[enemy].count

      victim = board[to]
      while true
        score += Pieces::get_value_by_sym(victim)
        return alpha if score <= alpha || own_counter >= own_attackers || victim.nil?  # stand pat 
        victim = board[attackers[own][own_counter]] 
        own_counter += 1
        beta = score if score < beta # beta update

        score -= Pieces::get_value_by_sym(victim)
        return beta if score >= beta || enemy_counter >= enemy_attackers || victim.nil?  # stand pat
        victim = board[attackers[enemy][enemy_counter]]  
        enemy_counter += 1
        alpha = score if score > alpha  # alpha update
      end
    end

    def self.reset_counters
      $main_calls, $quiescence_calls, $evaluation_calls, $memory_calls, $passes = 0, 0, 0, 0, 0
    end

    def self.clear_memory
      $tt.clear  # clear the transposition table.  At TT sizes above 500k, lookup times begin to 
                 # outweigh benefit of additional entries.
      $killer.clear
      $history.clear
      GC.start
    end

    # Module interface

    def self.select_move(node, max_ply=6, aggregator=nil, verbose=true)
      Chess::current_game.clock.restart
      @node, @max_depth, @aggregator, @verbose = node, max_ply*PLY_VALUE, aggregator, verbose
      @iid_minimum = Chess::max(@max_depth-TWO_PLY, FOUR_PLY)
      @previous_value = Chess::current_game.previous_value || nil
      
      reset_counters
      clear_memory

      move, value = block_given? ? yield : iterative_deepening_mtdf

      if @verbose && !move.nil? 
        puts "Move chosen: #{move.print}, Score: #{value}, TT size: #{$tt.size}"
      end 
      return move, value
    end 

  end
end



