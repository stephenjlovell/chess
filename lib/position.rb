
module Application
  module Position

    # ChessPosition describes the game state as of a specific turn. Should describe the following:
      # Piece placement
      # Side to move
      # Castling rights
      # En passant target square
      # Halfmove Clock

    # Each node in the Search Tree (DAG) will contain a Position object, so this class needs to be
    # as space efficient as possible.

    class ChessPosition
      attr_accessor :pieces, :board

      def initialize(board, pieces)
        @board = board
        @pieces = pieces
      end

      def get_moves
        moves = []
        @pieces.each do |piece|
           moves += piece.get_moves(@board)
        end
        return moves
      end

      def to_s
        # return a string decribing the position in Forsyth-Edwards Notation.
      end

    end

  end
end


