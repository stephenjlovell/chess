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

module Chess # top-level application namespace.

  # Application-level globals:
  $INF = 1.0/0.0
  $tt = nil  # global access to transposition table instance.


  def self.current_game
    @current_game ||= Chess::Game.new
  end

  def self.current_game=(game)
    @current_game = game  # may be needed in a future load_game method.
  end

  def self.new_game(ai_player = :b, time_limit = 60.0)
    @current_game = Chess::Game.new(ai_player, time_limit)
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

  class MoveHistory
    attr_accessor :history

    def initialize
      @index = 0
      @history = []
    end

    def save(move)
      @history.slice!(@index..-1) if @index < @history.count
      @history << move
      @index += 1
    end

    def undo(position)
      @index -= 1
      MoveGen::unmake!(position, @history[@index])
    end

    def redo(position)
      MoveGen::make!(position, @history[@index])
      @index += 1
    end
  end

  class Game
    attr_accessor :position, :halfmove_clock, :tt, :clock, :move_history
    attr_reader :ai_player, :opponent
    
    def initialize(ai_player = :b, time_limit = 120.0)
      board = Board.new
      @position = Position::ChessPosition.new(board,Pieces::setup(board),:w,0)
      @halfmove_count = 0
      @move_history = MoveHistory.new
      @ai_player, @opponent = ai_player, FLIP_COLOR[ai_player]
      @tt = Memory::TranspositionTable.new
      $tt = @tt
      @clock = Clock.new(time_limit)
    end

    def move_clock
      @halfmove_count / 2
    end

    def print # print game state info along with board representation
      opp_score, ai_score = score(@ai_player), score(@opponent)
      scoreboard = "| Move: #{move_clock} | Ply: #{@halfmove_count} " +
                   "| Turn: #{@position.side_to_move.to_s} " +
                   "| AI Score: #{ai_score} | Your Score: #{opp_score} |"
      separator = "-" * scoreboard.length
      puts separator, scoreboard, separator, "\n"
      @position.board.print
    end

    def score(enemy_color)
      [(1040 - (Evaluation::base_material(@position, enemy_color)/100)),0].max
    end

    def stage  # used during evaluation
      if @halfmove_count > 60
        :late_game
      elsif @halfmove_count > 30
        :mid_game
      else
        :opening
      end
    end

    def undo_move
      @move_history.undo(@position)
    end

    def redo_move
      @move_history.redo(@position)
    end

    def save_move(move)
      @move_history.save(move)
    end

    def human_move(move)  
      take_turn do
        MoveGen::make!(@position, move)
      end
    end

    def ai_move
      take_turn do 
        move = Search::select_move(@position)
        MoveGen::make!(@position, move)
      end
    end

    def take_turn
      # add any code that must run at beginning of each turn
      yield
      @halfmove_count += 1
      self.print
      @clock.end_turn
    end

  end

end




