module Application
  module CLI  # this module provides a basic command-line interface for playing human vs AI
              # games.  Mainly for demo / debug purposes prior to building out main UCI GUI.
    
    def self.play # main CLI method.  Gets and responds to user input.
      print "Welcome to Steve's Ruby Chess!  Choose your color (w/b):  "
      $stdout.flush
      human_color = gets.chomp
      if human_color == "w" || human_color == "b"
        time_limit = 20.0
        ai_color = human_color == "w" ? :b : :w
        Application::new_game(ai_color, time_limit)
      end 
      Application::print
      input = ""
      until input == "quit" || input == "q" || input == "exit" do
        unless input == ""
          Application::current_game.human_move(input) if human_color == "w"
          Application::current_game.make_move
          Application::current_game.human_move(input) if human_color != "w"
        end
        print "where would you like to move?  "
        $stdout.flush
        input = gets.chomp
      end
      puts "Thanks for playing!  See you soon."
    end

  end
end