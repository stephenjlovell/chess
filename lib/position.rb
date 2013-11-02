
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


      def initialize(board, pieces, side, en_passant_target = nil)
        @board = board
        @pieces = pieces
        @side_to_move = side
        @en_passant_target = en_passant_target
      end

      def get_moves
        moves = []
        @pieces[:side_to_move].each { |piece| moves += piece.get_moves(@board) }
        return moves.sort { |x,y| y[2] <=> x[2] }
      end

      def to_s
         # return a string decribing the position in Forsyth-Edwards Notation.
      end

    end


    def self.create_position(position, move)
      en_passant_target = nil

      new_pieces = position.pieces[position.side_to_move].collect do |piece| 
        if piece == move[0]
          piece.class.new(move[1][0],move[1][1],piece.color)
        else
          piece.copy
        end
      end

      side_to_move = if position.side_to_move == :w; :b; else; :w; end

      new_board = Application::Board.new
      new_board.place_pieces(new_pieces)

      ChessPosition.new(new_board, new_pieces, side_to_move, en_passant_target)
    end

  end
end




