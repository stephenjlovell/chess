
module Application
  module Position

    # ChessPosition describes the game state as of a specific turn. Should describe the following:
    # Piece placement, side to move, castling rights, en passant target square
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
        @pieces[@side_to_move].each { |coordinates, piece| moves += piece.get_moves(self) }  # refactor 
        return moves.sort { |x,y| y.capture_value <=> x.capture_value }
      end

      def en_passant_target?(row, column)
        return false if @en_passant_target.nil?
        if @en_passant_target[0] == row && @en_passant_target[1] == column
          true
        else
          false
        end
      end

      def copy
        pieces = { w: {}, b: {} }
        @pieces.each do |color, coordinates_hash|
          @pieces[color].each do |coordinate, piece|
            pieces[color][coordinate] = piece.class.new(piece.position[0], piece.position[1], piece.color)
          end
        end
        en_passant_target = if @en_passant_target.nil?
          nil
        else
          [@en_passant_target[0], @en_passant_target[1]]
        end 
        ChessPosition.new(@board.copy, pieces, @side_to_move, en_passant_target) 
      end

      def move!(move) #should accept a move object/array
        Movement::move!(move)
      end

      def to_s
         # return a string decribing the position in Forsyth-Edwards Notation.
      end

    end

    def self.create_position(position, move) # returns a new position object representing the
      # game state that results from the current player at position taking the specified move.
      en_passant_target = nil
      new_position = position.copy
      new_position.move!(move)
      new_position.side_to_move = if position.side_to_move == :w; :b; else; :w; end
      return new_position
    end

  end
end




