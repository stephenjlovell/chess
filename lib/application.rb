require './lib/board.rb'
require './lib/position.rb'
require './lib/pieces.rb'
require './lib/move.rb'

module Application
  # define application-level behavior here.

  class << self
    def current_game
      @current_game || Application::Game.new
    end

    def current_game=(game)
      @current_game = game  # may be needed in a future load_game method.
    end

    def new_game
      @current_game = Application::Game.new
    end
  end

  class Game
    attr_accessor :board, :current_position  
    # current_position represents the root node in current search tree.
    
    def initialize
      @board = Board.new
      @current_position = Position::ChessPosition.new
      @current_position.pieces = Position::setup_pieces(@board)
    end
  end

end