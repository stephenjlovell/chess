require './lib/board.rb'
require './lib/movement.rb'
require './lib/pieces.rb'
require './lib/position.rb'
require './lib/evaluation.rb'
require './lib/search.rb'

module Application # define application-level behavior in this module and file.

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

    def current_position # represents the root node in current search tree.
      @current_position ||= current_game.position
    end
  end

  class Game
    attr_accessor :position  
    
    def initialize
      board = Application::Board.allocate
      board.setup
      pieces = Pieces::setup(board)
      @position = Position::ChessPosition.new(board, pieces, :w)
    end

    # Halfmove clock will be defined at the game level.

  end

end




