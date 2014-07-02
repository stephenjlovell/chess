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

    #  The Position object contains all information needed to fully describe any possible state of play in a game 
    #  of chess.  This includes piece placement, side to move (the side that moves next from the current position),
    #  castling rights for both sides,the location of the en-passant target square (if any), and the current 
    #  halfmove count (for tracking draws by the Fifty Move Rule).  
    #
    #  1. A single position instance is stored for the current game, and is updated by making
    #     and unmaking moves. A single instance is also maintained and updated throughout the search.
    #     In early testing, make/unmake (or 'incremental update') reduced overhead cost of move generation by a 
    #     factor of 3-4 compared to the 'copy/make' approach. 
    #  2. Some heuristics needed during Evaluation can be stored in the position object and incrementally
    #     updated during make/unmake, eliminating the need to loop over the piece lists to recalculate these
    #     heuristics for each evaluation call. Material balance and king tropism bonus are updated in this way.

    class Position
      attr_accessor :board, :pieces, :side_to_move, :enemy, :halfmove_clock, :castle, :enp_target, 
                    :hash, :king_location, :tropism

      def initialize(board=nil, side_to_move=:w, castle=0b1111, enp_target=nil, halfmove_clock=0)
        @side_to_move, @castle, @enp_target, @halfmove_clock = side_to_move, castle, enp_target, halfmove_clock
        @enemy = FLIP_COLOR[@side_to_move]
        @board = board || Board.new
        # Generate bitboards for each piece color and type given the board representation.
        @pieces = Bitboard::PiecewiseBoard.new(@board)
        # Calculate an initial Zobrist hash key for the position.
        @hash = @board.hash ^ Memory::enp_key(enp_target) ^ (@side_to_move==:w ? 1 : 0)
      end

      def own_king_location
        @pieces.get_king_square(@side_to_move)
      end

      def enemy_king_location
        @pieces.get_king_square(@enemy)
      end

      # Perform a static evaluation of the current position to asses its heuristic value to the current side.
      # This method should only be called from positions that are relatively 'quiescent', i.e. where big swings in
      # material balance are not likely.
      def value(in_check = nil)
        Evaluation::evaluate(self, in_check)
      end

      def in_endgame?
        @pieces.endgame?(@side_to_move)
      end

      def endgame?(side)
        @pieces.endgame?(side)
      end

      def in_check?
        side_in_check?(@pieces, @side_to_move)
      end

      def enemy_in_check?
        side_in_check?(@pieces, @enemy)
      end
      
      def avoids_check?(move, in_check) # while in check, only legal evasions are generated.
        in_check || move_avoids_check?(@pieces, move.piece, move.from, move.to, @side_to_move)
      end

      # Verify that the move is legal and does not leave the current side's king in check.
      def legal?(move)
        move_is_legal?(@pieces, @board.squares, move.from, move.to, @side_to_move)
      end

      def gives_check?(move)
        move_gives_check?(@pieces, @board.squares, move.from, move.to, @side_to_move, move.promoted_piece)
      end

      # Return a string decribing the position in Forsyth-Edwards Notation.
      def to_s  
        Notation::position_to_fen(self)
      end

      def inspect
        "<Chess::Position <@board:#{@board.inspect}> <@pieces:#{@pieces.inspect}> <@side_to_move:#{@side_to_move}>>"
      end

      # Moves should be ordered in descending order of expected subtree value. Better move ordering produces a greater
      # number of alpha/beta cutoffs during search, reducing the size of the actual search tree toward the minimal tree.

      def get_moves(depth, enhanced_sort=false, in_check=false) 
        promotions, captures, moves = [], [], []

        if in_check
          MoveGen::get_evasions(@pieces, @side_to_move, @board.squares, @enp_target, promotions, captures, moves)
        else
          MoveGen::get_captures(@pieces, @side_to_move, @board.squares, @enp_target, captures, promotions)
          MoveGen::get_non_captures(@pieces, @side_to_move, @castle, moves, in_check)
        end

        # At higher depths, expend additional effort on move ordering.

        if enhanced_sort
          enhanced_sort(promotions, captures, moves, depth)
          # puts self.to_s
          # @board.print
          # captures.each {|c| puts "#{c}: #{c.see}" }
        else
          promotions + sort_captures_by_see!(captures) + history_sort!(moves)
        end

        # promotions + sort_captures_by_mvv_lva!(captures) + history_sort!(moves)

        # promotions + sort_captures_by_see!(captures) + history_sort!(moves)
        
        # enhanced_sort(promotions, captures, moves, depth)
      end

      # Generate only moves that create big swings in material balance, i.e. captures and promotions. 
      # Used during Quiescence search to seek out positions from which a stable static evaluation can 
      # be performed.
      def get_captures(evade_check) 
        # During quiesence search, sorting captures by SEE has the added benefit of enabling the pruning of bad
        # captures (those with SEE < 0). In practice, this reduced the average number of q-nodes by around half. 
        promotions, captures = [], []
        if evade_check
          moves = []
          MoveGen::get_evasions(@pieces, @side_to_move, @board.squares, @enp_target, promotions, captures, moves)
          promotions + sort_captures_by_see!(captures) + history_sort!(moves)
        else
          MoveGen::get_winning_captures(@pieces, @side_to_move, @board.squares, @enp_target, captures, promotions)
          promotions + sort_winning_captures_by_see!(captures)
        end
      end

      def get_all_captures
        promotions, captures = [], []
        MoveGen::get_captures(@pieces, @side_to_move, @board.squares, @enp_target, captures, promotions)
        promotions + sort_captures_by_see!(captures)
      end

      def sort_captures_by_mvv_lva!(captures)
        captures.sort_by! { |c| -c.mvv_lva }
      end

      def sort_captures_by_see!(captures)
        captures.sort_by! { |c| -((c.see_score(self)<<5) + c.mvv_lva) }
      end

      def sort_winning_captures_by_see!(captures)
        captures.sort_by! { |c| -((c.see<<5) + c.mvv_lva) }
      end     

      def history_sort!(moves)
        moves.sort_by! { |m| -$history[m.piece][m.to] }
      end 


      def enhanced_sort(promotions, captures, moves, depth)
        winning_captures, losing_captures = split_captures_by_see!(captures)
        killers, non_killers = split_killers(moves, depth)
        promotions + winning_captures + killers + losing_captures + non_killers
      end


      def split_killers(moves, depth)
        k = $killer[depth]
        killers, non_killers = [], []
        moves.each { |m| (m==k.first || m==k.second || m==k.third) ? killers << m : non_killers << m }
        return killers, history_sort!(non_killers)
        # moves.inject([[],[]]) { |a, m| (m==k.first||m==k.second||m==k.third) ? a[0] << m : a[1] << m; a }
      end





      def split_captures_by_see!(captures)
        winning, losing = [], []
        sort_captures_by_see!(captures).each { |m| m.see >= 0 ? winning << m : losing << m }
        return winning, losing
        # sort_captures_by_see!(captures).inject([[],[]]) { |a, m| m.see >= 0 ? a[0] << m : a[1] << m; a }
      end

    end

end











