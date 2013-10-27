module Application
  # define application-level variables here.
  class Game
    attr_accessor :board
    attr_accessor :current_position
    
    def initialize
      @board = Board.new
      @current_position = ChessPosition.new
      @current_position.setup_pieces(@board)
    end
  end

end