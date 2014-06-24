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

require './lib/utilities.rb'

module Chess
  module CLI  # this module provides a basic command-line interface for playing human vs AI games.  

    def self.play  # Main CLI method.  Gets and responds to user input.
      return if setup.nil?
      input = ""
      until quit?(input) do
        parse_input(Chess::current_game, input)
        break if winner
        print "It's your turn.  Enter a command:  "
        $stdout.flush
        input = gets.chomp
      end
    end

    def self.setup  # Prompts the user to choose their color, and starts up a new game.
      puts "Welcome to RubyChess!"
      input, valid_color = "", false
      until valid_color
        print  "Choose your color (w/b):  "
        $stdout.flush
        input = gets.chomp
        return nil if quit?(input) # sentinel indicating user wants to exit the game.
        valid_color = input == "w" || input == "b" || input == "white" || input == "black"
        if valid_color
          time_limit = 12.0
          ai_color = input == "w" || input == "white" ? :b : :w
          game = Chess::new_game(ai_color, time_limit)
          
          if game.ai_player == :w
            puts "White always moves first..."
            game.ai_move 
          else
            game.print
          end
        elsif !help?(input)
          puts "Not a valid color.  Please choose white (w) or black (b):  "
        end
      end
      return Chess::current_game
    end

    def self.parse_input(game, input) # Parses user input, and executes the specified command if command is valid.
      return nil if help?(input)
      if input == "undo"
        game.undo_move
      elsif input == "redo"
        game.redo_move
      elsif input == "print history"
        game.print_history
      elsif input == "print history details"
        game.print_history_details
      elsif input == "fen"
        puts game.position.to_s
      elsif input[0..3] == "load"
        load(input[5..-1])
      elsif !input.empty?
        move = parse_move(input)
        return nil unless move
        game.human_move(move) 
        game.ai_move  # If AI is in checkmate, game.winner flag will be set.
      end
    end

    def self.quit?(input)  # Check if the user is trying to exit the game.
      if input == "quit" || input == "q" || input == "-q" || input == "exit"
        puts "Thanks for playing!  See you soon."
        return true
      end
      false
    end

    HELP = [ { command: 'help', description: "displays a help screen with a list of valid commands... including this one." },
             { command: 'quit', description: 'ends the game and exits the program.  you may also enter "q" or "exit" to quit.' },
             { command: 'undo', description: 'undoes the most recent full move (undoing the most recent action for each side).' },
             { command: 'redo', description: 'replays the next full move.  Only available if move(s) have been undone.' },
             { command: 'print history', description: 'prints a list of the moves made by each player.' }, 
             { command: 'print history details', description: 'prints the move list, along with the position in FEN notation.' },
             { command: 'load <FEN>', description: 'loads the chess position specified by <FEN> in FEN notation.' },
             { command: 'fen', description: 'prints out the current position in FEN notation' } ]

    def self.help?(input)  # prints out a help menu and a table listing valid commands. 
      if input == "help" || input == "h" || input == "-h"
        separator = "-"*44
        puts "\n#{separator} RubyChess Help #{separator}"
        puts "To move one of your pieces, enter the square you want to move from, \n" + 
             "and the square the piece is moving to.  For example: a1a2 \n" +
             "To castle, simply move your king 2 squares to the left or right. \n"
        puts "The following commands are also available:\n\n" 
        tp HELP, :command, description: { width: 202 }
        puts "\n"
        return true
      end
      false
    end

    def self.parse_move(input) # translates an input string into a valid move object.
      begin
        Notation::str_to_move(Chess::current_game.position, input)
      rescue Notation::InvalidMoveError => e
        puts e.message
        return nil
      end
    end

    # Accepts a string representing a valid chess position in Forsyth-Edwards Notation (FEN), and updates the
    # current game state to match the specified position.  This can be used to load and play chess puzzles, or 
    # to resume a previous game.
    def self.load(input)
      begin
        pos = Notation::fen_to_position(input)
        Chess::new_game(pos.enemy)
        Chess::current_game.position = pos
        Chess::current_game.print
      rescue Notation::NotationFormatError => e
        puts e.message
        return nil
      end
    end

    def self.winner
      unless Chess::current_game.winner.nil?
        Chess::current_game.print_history_details
        if Chess::current_game.winner == Chess::current_game.opponent
          puts "\nCheckmate! You win!! \n\n"
        else
          puts "\nYour forces are defeated! I for one welcome our new robot overlords... \n\n"
        end
        true
      end
      false
    end

  end
end











