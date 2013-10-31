require './lib/board.rb'
require './lib/pieces.rb'
require './lib/position.rb'
require './lib/evaluation.rb'
require './lib/search.rb'

module Application
  # define application-level behavior here.

  class << self
    def current_game
      @current_game ||= Application::Game.new
    end

    def current_game=(game)
      @current_game = game  # may be needed in a future load_game method.
    end

    def new_game
      @current_game = Application::Game.new
    end

    def current_position
      @current_position ||= current_game.position
    end
  end

  class Game
    attr_accessor :position  
    # Application::current_position represents the root node in current search tree.
    
    def initialize
      board = Application::Board.allocate
      board.setup
      pieces = Pieces::setup(board)
      @position = Position::ChessPosition.new(board, pieces)
    end 
  end

end