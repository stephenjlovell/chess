module Chess
  module CLI  # this module provides a basic command-line interface for playing human vs AI
              # games.  Mainly for demo / debug purposes prior to building out main UCI GUI.
    
    def self.play # main CLI method.  Gets and responds to user input.
      print "Welcome to Steve's Ruby Chess!  Choose your color (w/b):  "
      $stdout.flush
      human_color = gets.chomp
      if human_color == "w" || human_color == "b"
        time_limit = 20.0
        ai_color = human_color == "w" ? :b : :w
        Chess::new_game(ai_color, time_limit)
      end

      Chess::current_game.print
      
      input = ""
      until input == "quit" || input == "q" || input == "exit" do
        unless input == ""
          move = parse_input(input)
          Chess::current_game.human_move(move) if human_color == "w"
          Chess::current_game.ai_move
          Chess::current_game.human_move(move) if human_color != "w"
        end
        print "where would you like to move?  "
        $stdout.flush
        input = gets.chomp
      end
      puts "Thanks for playing!  See you soon."
    end


# Move format used by UCI:

# Examples:  e2e4, e7e5, e1g1 (white short castling), e7e8q (for promotion)



    def self.parse_input(input)
      # in addition to making valid moves, this should let the player undo/redo their previous move



    end



    def self.parse_move(input)
      position = Chess::current_game.position
      from = Location::get_location_from_string(input[0..1])
      to = Location::get_location_from_string(input[-2..-1])

      # select a move strategy based on input


      Move::Factory.build(piece, from, to, )
      # compose a move object that uses the appropriate strategy.
    end

  end
end











