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
        best_move, value = send(@algorithm)
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
        guess = @root.value
        best_move = nil
        value = -$INF
        puts "\nd | main | quies. | total | evals | memory | non-replacements"
        previous_pv, current_pv  = Memory::PVStack.new, Memory::PVStack.new
        (1..depth).each do |d|
          Search::reset_counters
          current_pv = Memory::PVStack.new
          best_move, value = yield(guess, d*4, previous_pv, current_pv)
          total_calls = 0.0 + $main_calls + $quiescence_calls
          puts "#{d} |m #{$main_calls/total_calls} |q #{$quiescence_calls/total_calls} |t #{total_calls} |e #{$evaluation_calls} |m #{$memory_calls} |n #{$non_replacements}"
          guess = value
          # current_pv.print
          previous_pv = current_pv
          if Application::current_game.clock.time_up?
            puts "evaluation time ran out after depth #{d}"; break
          end
        end
        current_pv.print
        return best_move, value
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
          best_move, g = alpha_beta(depth, beta-1, beta, previous_pv, current_pv)
          if g < beta then upper_bound = g else lower_bound = g end
        end
        return best_move, g, current_pv
      end

      def alpha_beta(depth=@max_depth/4, alpha=-$INF, beta=$INF, previous_pv=nil, parent_pv=nil)
        depth ||= @max_depth
        parent_pv ||= Memory::PVStack.new
        # puts "initial value: #{@root.value}"

        result, best_value, best_move, mate_possible = -$INF, -$INF, nil, true
        current_pv = Memory::PVStack.new

        pv_move = previous_pv.next_move if previous_pv
        if pv_move
          $main_calls += 1
          mate_possible = false

          MoveGen::make_unmake!(@root, pv_move) do
            result = -alpha_beta_main(@root, depth-4, -beta, -alpha, previous_pv, current_pv, true)
            # puts "#{pv_move.to_s}: #{result}"
          end
          if result > best_value
            best_value = result 
            best_move = pv_move
          end
          if best_value > alpha  # child node now a PV node.
            alpha = best_value
            append_pv(parent_pv, current_pv, pv_move)
          end
        end

        entry = $tt.retrieve(@root)
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

        @root.edges.each do |move|
          $main_calls += 1
          mate_possible = false

          MoveGen::make_unmake!(@root, move) do
            extension = 4  # start with a full ply extension.
            # extension -= 1 if move.capture_value >= 1.5
            # extension -= 2 if @root.in_check?
            result = -alpha_beta_main(@root, depth-extension, -beta, -alpha, previous_pv, current_pv)
            # puts "#{move.to_s}: #{result}"
          end

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
        result = $tt.store_result(@max_depth, mate_possible, @root, depth, best_value, alpha, beta, best_move)
        return best_move, result
      end

      def alpha_beta_main(node, depth, alpha=-$INF, beta=$INF, previous_pv=nil, parent_pv=nil, on_pv=false)

        result, best_value, best_move, mate_possible = -$INF, -$INF, nil, true
        current_pv = Memory::PVStack.new

        
        if on_pv  # try the PV move first
          pv_move = previous_pv.next_move
          if pv_move
            mate_possible = false
            
            MoveGen::make_unmake!(node, pv_move) do
              result = -alpha_beta_main(node, depth-4, -beta, -alpha, previous_pv, current_pv, true)
            end

            if result > best_value
              best_value = result 
              best_move = pv_move
            end
            if best_value > alpha # child node now a PV node.
              alpha = best_value
              append_pv(parent_pv, current_pv, pv_move)
            end
          end
        end
        
        entry = $tt.retrieve(node)  # then probe the transposition table for a hash move:
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
          return $tt.store_result(@max_depth, mate_possible, node, 0, best_value, alpha, beta)  
        end

        node.edges.each do |move|
          $main_calls += 1
          mate_possible = false  # if legal moves are available, it's not checkmate.

          MoveGen::make_unmake!(node, move) do
            extension = 4  # start with a full ply extension.
            # extension -= 1 if move.capture_value >= 1.5
            # extension -= 2 if node.in_check?
            result = -alpha_beta_main(node, depth-extension, -beta, -alpha, previous_pv, current_pv)
          end
          if result > best_value
            best_value = result 
            best_move = move
          end
          if best_value > alpha # child node now a PV node.
            alpha = best_value
            append_pv(parent_pv, current_pv, move)
          end
          break if best_value >= beta
        end

        $tt.store_result(@max_depth, mate_possible, node, depth, best_value, alpha, beta, best_move)
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

        result, best_move, see_squares, mate_possible = -$INF, nil, {}, true

        node.tactical_edges.each do |move|

          see_squares[move.to] ||= Search::get_see_score(node, move.to) # perform static exchange evaluation
          next if see_squares[move.to] <= 0

          $quiescence_calls += 1
          mate_possible = false

          MoveGen::make_unmake!(node, move) do
            result = -quiescence(node, depth-4, -beta, -alpha)
          end
          
          if result > best_value
            best_value = result 
            best_move = move
          end
          alpha = best_value if best_value > alpha
          break if best_value >= beta

        end

        $tt.store_result(@max_depth, mate_possible, node, depth, best_value, alpha, beta, best_move)
      end

      def append_pv(parent_pv, current_pv, move)
        parent_pv.clear
        parent_pv[0] = move
        parent_pv += current_pv  # merge PVStack for child node into PVStack for parent node.
      end
    end  # end Strategy class

    # Module helper methods

    def self.select_position(node, algorithm = :iterative_deepening_mtdf, max_depth=4)
      reset_counters
      $tt = Application::current_game.tt
      strategy = Strategy.new(node, max_depth, algorithm)
      best_move, value = strategy.select_position
      puts value
      return best_move
    end 

    def self.reset_counters
      $main_calls, $quiescence_calls, $evaluation_calls, $memory_calls, $non_replacements = 0, 0, 0, 0, 0
    end

    def self.get_see_score(position, to)
      attack_squares = { w: position.board.attackers(to, :w), 
                         b: position.board.attackers(to, :b) }
      attack_squares.each do |key, arr|  # more valuable pieces are listed first
        arr.sort! { |x,y| Pieces::PIECE_SYM_ID[position.board[y]] <=> Pieces::PIECE_SYM_ID[position.board[x]] } 
      end
      position.board.print
      puts to, attack_squares
      value = static_exchange_evaluation(position.board, to, position.side_to_move, attack_squares)
      puts value
      return value
    end

    def self.static_exchange_evaluation(board, to, side, attack_squares)
      value = 0
      from = attack_squares[side].pop # get the next attacking square
      if from
        # simulate making the capture
        sym = board[to]  # save the captured symbol for unmake
        board[to] = board[from]
        board[from] = nil 

        side == :w ? :b : :w
        capture_value = Pieces::get_value_by_sym(sym)
        value = capture_value - static_exchange_evaluation(board, to, side, attack_squares)

        # simulate unmaking the capture
        board[from] = board[to]
        board[to] = sym
      end
      return value
    end

  end
end



