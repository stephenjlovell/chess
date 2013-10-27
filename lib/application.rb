require './lib/board.rb'
require './lib/position.rb'
require './lib/pieces.rb'

module Application
  # define application-level variables here.

  class << self
    attr_accessor :current_game
  end

  def initialize
    self.current_game = Application::Game.new
  end

  class Game
    attr_accessor :board
    attr_accessor :current_position
    
    def initialize
      @board = Board.new
      @current_position = Position::ChessPosition.new
      @current_position.pieces = Position::setup_pieces(board)
    end
  end

end