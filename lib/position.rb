
module Application
  module Position
    class PiecePosition  # stores coordinates of a piece on the chessboard.
      attr_reader :row, :column

      def initialize(row, column)
        @row, @column = row, column
      end

    end

    # ChessPosition describes the game state as of a specific turn. Should describe the following:
      # Piece placement 
      # Side to move
      # Castling rights
      # En passant target square
      # Halfmove Clock

    # Each node in the Search Tree (DAG) will contain a Position object, so this class needs to be
    # as space efficient as possible.

    class ChessPosition
      attr_accessor :pieces

      def initialize
        @pieces = []
      end

      def to_s
        # return a string decribing the position in Forsyth-Edwards Notation.
      end

    end


    def self.setup_pieces(board)  
      # returns an array of new chess piece objects corresponding to the 
      # board representation specified in board.
      pieces = []
      board.each_with_index do |row, column|
        row.each_with_index do |sym, row|
          unless sym == nil || sym == :XX
            pieces << Pieces::create_piece_by_sym(row,column, sym) 
          end
        end
      end
      return pieces
    end

  end
end


