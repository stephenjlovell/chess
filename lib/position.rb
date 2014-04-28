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
        # Set initial king tropism bonuses (closeness of a side's non-king pieces to the enemy king) for each side.
        # King tropism bonuses are incrementally updated during move generation.
        
        # @tropism = { w: Evaluation::king_tropism(self, :w), b: Evaluation::king_tropism(self, :w) } 
      end

      def own_material
        @pieces.get_material(@side_to_move)
      end

      def enemy_material
        @pieces.get_material(@enemy)
      end

      def own_tropism
        @tropism[@side_to_move]
      end

      def own_tropism=(value)
        @tropism[@side_to_move] = value
      end

      def enemy_tropism
        @tropism[@enemy]
      end

      def enemy_tropism=(value)
        @tropism[@enemy] = value
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
      def value
        Evaluation::evaluate(self)
      end

      def in_endgame?
        own_material <= Pieces::ENDGAME_VALUE
      end

      def endgame?(side)
        @material[side] <= Pieces::ENDGAME_VALUE
      end

      def in_check?
        side_in_check?(@pieces, @side_to_move)
      end

      def enemy_in_check?
        side_in_check?(@pieces, @enemy)
      end

      # Verify that the given move would not leave the current side's king in check.
      def evades_check?(move)
        captured_piece = @board[move.to]
        piece, from, to = move.piece, move.from, move.to
        @pieces.relocate_piece(piece, from, to)

        if captured_piece > 0
          @pieces.remove_square(captured_piece, to)
          in_check = self.in_check?
          @pieces.add_square(captured_piece, to)
        else 
          in_check = self.in_check?   
        end
        @pieces.relocate_piece(piece, from, to)

        return !in_check
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

      def get_moves(depth, enhanced_sort) 
        promotions, captures, moves = [], [], []

        MoveGen::get_captures(@pieces, @side_to_move, @board.squares, @enp_target, captures, promotions)
        MoveGen::get_non_captures(@pieces, @side_to_move, @castle, moves)
        # At higher depths, expend additional effort on move ordering.

        # return promotions + if enhanced_sort
        #   enhanced_sort(captures, moves, depth)
        # else
        #   basic_sort(captures, moves)
        # end
        return promotions + basic_sort(captures, moves)
      end
      alias :edges :get_moves

      def enhanced_sort(captures, moves, depth)
        winning_captures, losing_captures = split_captures_by_see!(captures)
        killers, non_killers = split_killers(moves, depth)
        winning_captures + killers + losing_captures + non_killers
      end

      def basic_sort(captures, moves)
        sort_captures!(captures) + history_sort!(moves)
      end

      # Generate only moves that create big swings in material balance, i.e. captures and promotions. 
      # Used during Quiescence search to seek out positions from which a stable static evaluation can 
      # be performed.
      def get_captures # returns a sorted array of all possible moves for the current player.
        promotions, captures = [], []
        MoveGen::get_captures(@pieces, @side_to_move, @board.squares, @enp_target, captures, promotions)
        # During quiesence search, sorting captures by SEE has the added benefit of enabling the pruning of bad
        # captures (those with SEE < 0). In practice, this reduced the average number of q-nodes by around half. 
        # promotions + sort_captures_by_see!(captures)
        promotions + sort_captures!(captures)
      end
      alias :tactical_edges :get_captures

      def split_captures_by_see!(captures)
        winning, losing = [], []
        sort_captures_by_see!(captures).each do |m|
          if m.see >= 0
            winning << m
          else
            losing << m
          end
        end
        return winning, losing
      end

      def sort_captures_by_see!(captures)
        captures.each { |m| m.see_score(self) }
        captures.sort! do |x,y|
          if y.see > x.see
            1
          elsif y.see < x.see
            -1
          else
            y.mvv_lva <=> x.mvv_lva  # Rely on MVV-LVA in event of tie.
          end
        end
      end

      def sort_captures!(captures)
        captures.sort! { |x,y| y.mvv_lva <=> x.mvv_lva } # Z-A
      end

      def split_killers(moves, depth)
        k = $killer[depth]
        killers, non_killers = [], []
        moves.each do |m| 
          if m == k.first || m == k.second || m == k.third
            killers << m
          else
            non_killers << m 
          end
        end
        return killers, history_sort!(non_killers)
      end

      def history_sort!(moves)
        moves.sort! { |x,y| $history[y.piece][y.to] <=> $history[x.piece][x.to] }
      end

    end

end











