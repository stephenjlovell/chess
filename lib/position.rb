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
                    :hash, :king_location, :material, :tropism

      def initialize(board=nil, side_to_move=:w, castle=0b1111, enp_target=nil, halfmove_clock=0)
        @side_to_move, @castle, @enp_target, @halfmove_clock = side_to_move, castle, enp_target, halfmove_clock
        @enemy = FLIP_COLOR[@side_to_move]
        @board = board || Board.new
        # Create lists of pieces in play for each side.  This allows for move generation without having to scan 
        # the board.
        @pieces = create_pieces(@board) 
        # Calculate an initial Zobrist hash key for the position.
        @hash = @board.hash ^ Memory::enp_key(enp_target) ^ (@side_to_move==:w ? 1 : 0)
        # Find and store the initial location of each king. Locations are updated on make/unmake of king moves.
        @king_location = set_king_location
        # Set initial value of material (sum of each piece value adjusted for it's location on board) for each side.
        # material values are incrementally updated during move generation.
        @material = { w: Evaluation::material(self, :w, Evaluation::base_material(self, :w) <= Pieces::ENDGAME_VALUE), 
                      b: Evaluation::material(self, :b, Evaluation::base_material(self, :b) <= Pieces::ENDGAME_VALUE) }
        # Set initial king tropism bonuses (closeness of a side's non-king pieces to the enemy king) for each side.
        # King tropism bonuses are incrementally updated during move generation.
        @tropism = { w: Evaluation::king_tropism(self, :w), b: Evaluation::king_tropism(self, :w) } 
      end

      def own_pieces
        @pieces[@side_to_move]
      end

      def enemy_pieces
        @pieces[@enemy]
      end

      def own_material
        @material[@side_to_move]
      end

      def own_material=(value)
        @material[@side_to_move] = value
      end

      def enemy_material
        @material[@enemy]
      end

      def enemy_material=(value)
        @material[@enemy] = value
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
        @king_location[@side_to_move]
      end

      def own_king_location=(location)
        @king_location[@side_to_move] = location
      end

      def enemy_king_location
        @king_location[@enemy]
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
        @board.king_in_check?(self, @side_to_move)
      end

      def enemy_in_check?
        @board.king_in_check?(self, @enemy)
      end

      # Verify that the given move would not leave the current side's king in check.
      def evades_check?(move)
        if move.from == own_king_location 
          @board.evades_check?(self, move.from, move.to, @side_to_move, move.to)
        else
          @board.evades_check?(self, move.from, move.to, @side_to_move, own_king_location)
        end
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
        captures, promotions, moves = [], [], []
        # Loop over piece list for the current side, collecting moves available to each piece.
        own_pieces.each { |key, piece| piece.get_moves(self, key, moves, captures, promotions) }
        # At higher depths, expend additional effort on move ordering.
        return promotions + if enhanced_sort
          enhanced_sort(captures, moves, depth)
        else
          basic_sort(captures, moves, depth)
        end
      end
      alias :edges :get_moves

      def enhanced_sort(captures, moves, depth)
        winning_captures, losing_captures = split_captures_by_see!(captures)
        killers, non_killers = split_killers(moves, depth)
        castles = MoveGen::get_castles(self)
        winning_captures + killers + losing_captures + castles + non_killers
      end

      def basic_sort(captures, moves, depth)
        sort_captures!(captures) + MoveGen::get_castles(self) + history_sort!(moves)
      end

      # Generate only moves that create big swings in material balance, i.e. captures and promotions. 
      # Used during Quiescence search to seek out positions from which a stable static evaluation can 
      # be performed.
      def get_captures # returns a sorted array of all possible moves for the current player.
        captures, promotions = [], []
        # Loop over piece list for the current side, collecting capture moves and promotions available to each piece.
        own_pieces.each { |key, piece| piece.get_captures(self, key, captures, promotions) }
        
        # During quiesence search, sorting captures by SEE has the added benefit of enabling the pruning of bad
        # captures (those with SEE < 0). In practice, this reduced the average number of q-nodes by around half. 
        promotions + sort_captures_by_see!(captures)
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
        moves.sort! { |x,y| $history[y.piece.symbol][y.to] <=> $history[x.piece.symbol][x.to] }
      end

      private 

      # Create piece lists indexed by board location, based on the given board.
      def create_pieces(board)        
        pieces = { w: {}, b: {} }
        board.each_square_with_location do |r,c,sym|
          unless sym.nil?
            piece = create_piece_by_sym(sym)
            pieces[piece.color][Location::get_location_by_coordinates(r,c)] = piece
          end
        end
        return pieces
      end

      def create_piece_by_sym(sym)
        color, type = sym[0].to_sym, sym[1]
        case type
        when "P" then Pieces::Pawn.new(color)
        when "R" then Pieces::Rook.new(color)
        when "N" then Pieces::Knight.new(color)
        when "B" then Pieces::Bishop.new(color)
        when "Q" then Pieces::Queen.new(color)
        when "K" then Pieces::King.new(color)
        end
      end

      def set_king_location
        kings = {}
        @board.each_square_with_location do |r,c,s|
          if s == :wK
            kings[:w] = Location::get_location_by_coordinates(r,c)
          elsif s == :bK
            kings[:b] = Location::get_location_by_coordinates(r,c)
          end
        end
        return kings
      end

    end

end











