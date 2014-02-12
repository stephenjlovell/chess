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

require 'table_print'

module Chess # top-level application namespace.

  def self.current_game
    @current_game ||= Chess::Game.new
  end

  def self.current_game=(game)
    @current_game = game  # may be needed in a future load_game method.
  end

  def self.new_game(ai_player = :b, time_limit = 30.0)
    puts "Starting a new game." 
    puts "AI color: #{ai_player}, Your color: #{FLIP_COLOR[ai_player]}"
    Chess::Game.new(ai_player, time_limit)
    return @current_game
  end

  class Clock
    attr_reader :game_start

    def initialize(time_limit) 
      @game_start, @turn_start, @time_limit = Time.now, Time.now, time_limit
    end

    def time_up?
      (Time.now - @turn_start) > @time_limit
    end

    def restart
      @turn_start = Time.now
    end
  end

  History = Struct.new(:index, :position, :move)

  class MoveHistory
    attr_accessor :history

    def initialize
      @index = 0
      @history = []
    end

    def save(position, move)
      @history.slice!(@index+1..-1) if @index < @history.count-1
      @history << History.new(@history.count, position.to_s, move)
      @index = @history.count-1
    end

    def undo(position)    
      if @index >= 1
        MoveGen::unmake!(position, @history[@index].move)
        MoveGen::unmake!(position, @history[@index-1].move)
        @index -= 2
      else
        puts "no more moves to undo."
      end
    end

    def redo(position)
      if @index <= @history.count-2
        MoveGen::make!(position, @history[@index+1].move)
        MoveGen::make!(position, @history[@index+2].move)
        @index += 2
      else
        puts "no more moves to redo."
      end
    end

    def print
      puts "------Move History (#{@history.count} total)------"
      tp @history, :index, :move
      puts "\n"
    end

    def print_details
      puts "------Move History Details (#{@history.count} total)------"
      tp @history, :index, :move, position: {width: 200}
      puts "\n"
    end
  end

  class Game
    attr_accessor :position, :halfmove_clock, :tt, :clock, :move_history, :game_over
    attr_reader :ai_player, :opponent
    
    def initialize(ai_player = :b, time_limit = 30.0)
      board = Board.new
      @position = Position::ChessPosition.new(board,Pieces::setup(board),:w,0)
      @halfmove_count = 0
      @move_history = MoveHistory.new
      @ai_player, @opponent = ai_player, FLIP_COLOR[ai_player]
      @tt = Memory::TranspositionTable.new
      $tt = @tt
      @game_over = false
      @clock = Clock.new(time_limit)
      Chess::current_game = self
    end

    def move_clock
      @halfmove_count / 2
    end

    def print # print game state info along with board representation
      opp_score, ai_score = score(@ai_player), score(@opponent)
      scoreboard = "| Move: #{move_clock} | Ply: #{@halfmove_count} " +
                   "| Turn: #{@position.side_to_move.to_s} " +
                   "| Castling: #{Notation::castling_availability(@position.castle)} " +
                   "| AI Score: #{ai_score} | Your Score: #{opp_score} |"
      separator = "-" * scoreboard.length
      puts separator, scoreboard, separator, "\n"
      @position.board.print
      if @position.in_check?

      end
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

    def save_move(position, move)
      @move_history.save(position, move)
    end

    def print_history
      @move_history.print
    end

    def print_history_details
      @move_history.print_details
    end

    def human_move(move)  
      save_move(@position, move)
      MoveGen::make!(@position, move)
      end_turn
    end

    def ai_move
      move = Search::select_move(@position)
      if move.nil?
        game_over = true
        end_turn
        return nil
      end
      save_move(@position, move)
      MoveGen::make!(@position, move)
      end_turn
    end

    private

    def end_turn
      @halfmove_count += 1
      self.print
      @clock.restart
    end

  end

end




