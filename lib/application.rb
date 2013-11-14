#-----------------------------------------------------------------------------------
# Copyright (c) 2013 Stephen J. Lovell
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#-----------------------------------------------------------------------------------

require './lib/board.rb'
require './lib/movement.rb'
require './lib/pieces.rb'
require './lib/position.rb'
require './lib/evaluation.rb'
require './lib/search.rb'
require './lib/user_interface.rb'

module Application # define application-level behavior in this module and file.

  class << self
    def current_game
      @current_game ||= Application::Game.new
    end

    def current_game=(game)
      @current_game = game  # may be needed in a future load_game method.
    end

    def new_game(ai_player = :w)
      @current_game = Application::Game.new(ai_player)
    end

    def current_position # represents the root node in current search tree.
      current_game.position
    end

    def current_side
      current_position.side_to_move
    end

    def current_board
      current_position.board
    end
  end

  class Game
    attr_accessor :position, :halfmove_counter, :ai_player, :opponent  
    
    def initialize(ai_player = :b)
      board = Application::Board.allocate
      board.setup
      pieces = Pieces::setup(board)
      @position = Position::ChessPosition.new(board, pieces, :w)
      @halfmove_counter = 0
      @ai_player = ai_player
      @opponent = ai_player == :w ? :b : :w
    end

    def move_count
      @halfmove_counter / 2
    end


    def take_turn
      begin_turn
      @position = Search::select_position
      end_turn 
    end

    # would be more idiomatic to roll begin_turn and end_turn into single method 
    # and pass a block to it.

    def begin_turn  

    end

    def end_turn # contains procedures common to AI and opponent turns.
      @halfmove_counter += 1
    end

  end

end




