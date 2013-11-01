module Application
  module Search # this module will define a search tree along with traversal algorithms for move selection.

    class Node # this class defines a single node in the search tree
      include Enumerable
      attr_accessor :edges

      def each # collection of all moves possible for current side to move.
        
      end

    end


    # class ChessPosition
    #   attr_accessor :pieces, :board
    #   attr_reader :side_to_move

    #   def initialize(board, pieces)
    #     @board = board
    #     @pieces = pieces
    #   end

    #   def get_moves
    #     moves = []
    #     @pieces.each { |piece|moves += piece.get_moves(@board) }
    #     return moves.sort { |x,y| y[2] <=> x[2] }
    #   end

    #   def to_s
    #     # return a string decribing the position in Forsyth-Edwards Notation.
    #   end

    # end


  end
end