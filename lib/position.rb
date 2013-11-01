
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
      attr_accessor :board, :pieces, :en_passant_target
      attr_reader :side_to_move


      def initialize(board, pieces, side)
        @board = board
        @pieces = pieces
        @side_to_move = side
      end

      def get_moves
        moves = []
        @pieces.each { |piece|moves += piece.get_moves(@board) }
        return moves.sort { |x,y| y[2] <=> x[2] }
      end

      def to_s
        # return a string decribing the position in Forsyth-Edwards Notation.
      end

    end


    def self.create_position(position, move)
      
      new_pieces = position.pieces.collect do |piece| 
        if piece == move[0]
          piece.class.new(move[1][0],move[1][1],piece.color)
        else
          piece.copy
        end
      end

      side_to_move = if position.side_to_move == :w
        :b
      else
        :w
      end

      new_board = position.board.new
      new_board.place_pieces(new_pieces)

      new_position = ChessPosition.new(new_board, new_pieces, side_to_move)


    end

  end
end




