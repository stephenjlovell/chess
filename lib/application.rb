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
require './lib/gui.rb'
require './lib/cli.rb'
require './lib/memory.rb'

module Application # define application-level behavior in this module and file.

  # application-level global constants:
  $INF = 1.0/0.0

  class << self
    def current_game
      @current_game ||= Application::Game.new
    end

    def current_game=(game)
      @current_game = game  # may be needed in a future load_game method.
    end

    def new_game(ai_player = :b, time_limit = 120.0)
      @current_game = Application::Game.new(ai_player, time_limit)
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

    def print
      current_game.print
    end
  end

  class Clock
    attr_reader :game_start

    def initialize(time_limit = 120.0) 
      @game_start, @turn_start, @time_limit = Time.now, Time.now, time_limit
    end

    def time_up?
      (Time.now - @turn_start) > 20.0
    end

    def restart
      @turn_start = Time.now
    end

    alias :end_turn :restart 
  end

  class Game
    attr_accessor :position, :halfmove_counter, :tt, :clock
    attr_reader :ai_player, :opponent
    
    def initialize(ai_player = :b, time_limit = 120.0)
      # board = Board.allocate
      # board.setup
      # pieces = Pieces::setup(board)
      # @position = Position::ChessPosition.new(board, pieces, :w)
      # @position.options[:castle] = { low: true, high: true }
      @position = Position::ChessPosition.allocate
      @position.setup
      @halfmove_counter = 0
      @ai_player = ai_player
      @opponent = ai_player == :w ? :b : :w
      @tt = Memory::TranspositionTable.new
      @clock = Clock.new(time_limit)
    end

    def move_count
      @halfmove_counter / 2
    end

    def print # print game state info along with board representation
      opp_score, ai_score = score(@ai_player), score(@opponent)
      scoreboard = "| Move: #{move_count} | Ply: #{@halfmove_counter} " + 
                   "| Turn: #{@position.side_to_move.to_s} " +
                   "| AI Score: #{ai_score} | Your Score: #{opp_score} |"
      separator = "-" * scoreboard.length
      puts separator, scoreboard, separator, "\n"
      @position.board.print
    end

    def score(enemy_color)
      [(1040 - (Evaluation::base_material(@position, enemy_color)/100)),0].max
    end

    def stage # return :early or :late
      
    end

    def human_move(description)  # for now, just assume human moves are valid.
      # puts "human_move(#{description})"
      take_turn do
        from = Movement::to_location(description[0..1]) # Eventually, handle exception if human provides invalid move.
        to = Movement::to_location(description[-2..-1])
        capture_value = Pieces::get_value_by_sym(Application::current_board[to])
        move = Movement::Move.new(@position, from, to, capture_value)
        @position = move.create_position
      end
    end

    def opponent_move
      # get move selected by opponent AI via UCI,
      # and pass to take_turn as a position object
    end

    def make_move
      take_turn { @position = Search::select_position }
    end

    def take_turn
      # add any code must run at beginning of each turn
      yield
      @halfmove_counter += 1

      #print pieces for debugging
      p self.position.pieces

      self.print
      @clock.end_turn
    end

  end

end




