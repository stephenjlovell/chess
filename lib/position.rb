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
  module Position

    class ChessPosition # Mutable description of the game state as of a specific turn.
      attr_accessor :board, :pieces, :side_to_move, :enemy, :halfmove_clock, :castle, :enp_target, 
                    :hash, :king_location, :material

      def initialize(board=nil, side_to_move=:w, halfmove_clock=0)
        @side_to_move, @halfmove_clock = side_to_move, halfmove_clock
        @board = board || Board.new
        @pieces = create_pieces(@board)
        @enp_target, @castle, @enemy  = nil, 0b1111, FLIP_COLOR[@side_to_move]
        @hash = @board.hash
        @king_location = set_king_location
        w_endgame = Evaluation::base_material(self, :w) <= Pieces::ENDGAME_VALUE # determine initial endgame state
        b_endgame = Evaluation::base_material(self, :b) <= Pieces::ENDGAME_VALUE
        @material = { w: Evaluation::material(self, :w, w_endgame), b: Evaluation::material(self, :b, b_endgame) } 
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

      def enemy_material
        @material[@enemy]
      end

      def own_material=(value)
        @material[@side_to_move] = value
      end

      def enemy_material=(value)
        @material[@enemy] = value
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

      def avoids_check?(move)
        if move.from == own_king_location 
          @board.avoids_check?(self, move.from, move.to, @side_to_move, move.to)
        else
          @board.avoids_check?(self, move.from, move.to, @side_to_move, own_king_location)
        end
      end

      def to_s  # return a string decribing the position in Forsyth-Edwards Notation.
        Notation::position_to_fen(self)
      end

      def inspect
        "<Chess::Position::ChessPosition <@board:#{@board.inspect}>" +
        "<@pieces:#{@pieces.inspect}> <@side_to_move:#{@side_to_move}>>"
      end

      def get_moves(first_moves, enhanced_sort=false) 
        promotion_captures, captures, promotions, moves = [], [], [], []

        own_pieces.each do |key, piece| 
          piece.get_moves(self, key, moves, captures, promotions, promotion_captures)
        end
        # if on the pv, invest some extra time ordering captures.  otherwise, use MVV-LVA.
        enhanced_sort ? sort_captures_by_see!(captures) : sort_captures!(captures) 
        sort_moves!(moves)  # ideally, killer moves should be searched before captures.
        # append move lists together in reasonable order:
        first_moves + promotion_captures + captures + promotions + MoveGen::get_castles(self) + moves
      end
      alias :edges :get_moves

      def get_captures(first_moves) # returns a sorted array of all possible moves for the current player.
        captures, promotion_captures = [], []
        own_pieces.each do |key, piece| 
          piece.get_captures(self, key, captures, promotion_captures)
        end
        sort_captures_by_see!(captures)
        first_moves + promotion_captures + captures
      end
      alias :tactical_edges :get_captures

      def sort_captures_by_see!(captures)
        captures.each { |m| m.see_score(self) }
        captures.sort! do |x,y|
          if y.see > x.see
            1
          elsif y.see < x.see
            -1
          else
            y.mvv_lva <=> x.mvv_lva  # rely on MVV-LVA in event of tie.
          end
        end
      end

      def sort_captures!(captures)
        captures.sort! { |x,y| y.mvv_lva <=> x.mvv_lva } # Z-A
      end

      def sort_moves!(moves) # sort remaining (non-capture) moves
        # sort regular moves by History or Killer heuristic
      end

      private 

      # Create a hash of chess pieces corresponding to the specified board representation. Used during initialization of
      def create_pieces(board)        
        pieces = { w: {}, b: {} }
        board.each_square_with_location do |r,c,sym|
          unless sym.nil?
            piece = create_piece_by_sym(sym)
            pieces[piece.color][Location::get_location(r,c)] = piece
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
            kings[:w] = Location::get_location(r,c)
          elsif s == :bK
            kings[:b] = Location::get_location(r,c)
          end
        end
        return kings
      end

    end

  end
end











