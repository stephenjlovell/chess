
module Application
  module Position

    # ChessPosition describes the game state as of a specific turn. Should describe the following:
      # Piece placement
      # Side to move
      # Castling rights
      # En passant target square


    class ChessPosition
      attr_accessor :board, :pieces, :en_passant_target
      attr_reader :side_to_move

      def initialize(board, pieces, side_to_move, en_passant_target = nil)
        @board = board
        @pieces = pieces   # pieces collection generated via Pieces::Setup
        @side_to_move = side_to_move
        @en_passant_target = en_passant_target
      end

      def get_moves # returns a sorted array of all possible moves for the current player.
        moves = []
        moves = @pieces[:side_to_move].each { |piece| moves += piece.get_moves(self) }
        return moves.sort { |x,y| y[2] <=> x[2] }
      end

      def copy
        pieces = { w: [], b: [] }
        pieces = @pieces.each do |key, value|
          pieces[key] = @pieces[key].collect do |piece|
            piece.class.new(piece.position[0], piece.position[1], piece.color)
          end
        end
        ChessPosition.new(@board.copy, @pieces.copy, @side_to_move, @en_passant_target) 
                          # en_passant_target is an array. need to deep copy this.
      end

      def move!( ) #should accept a move object/array
        
        @board.move!()
      end

      def to_s
         # return a string decribing the position in Forsyth-Edwards Notation.
      end

    end

    def self.create_position(position, move) # returns a new position object representing the
      # game state that results from the current player at position taking the specified move.
      en_passant_target = nil

      new_pieces = position.pieces[position.side_to_move].collect do |piece| 
        if piece == move[0]
          piece.class.new(move[1][0],move[1][1],piece.color)
          en_passant_target = [move[1][0],move[1][1]] if move[3]
        else
          piece.copy
        end
      end
      side_to_move = if position.side_to_move == :w; :b; else; :w; end
      new_board = Application::Board.new  # use the board.copy method here
      new_board.place_pieces(new_pieces)
      ChessPosition.new(new_board, new_pieces, side_to_move, en_passant_target)
    end

  end
end




