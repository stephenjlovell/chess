module Application
  module CLI  # this module provides a basic command-line interface for playing human vs AI
              # games.  Mainly for demo / debug purposes prior to building out main UCI GUI.
    
    def self.play # main CLI method.  Gets and responds to user input.
      print "Welcome to Steve's Ruby Chess!  Choose your team (w/b):  "
      team = gets.chomp
      if team == "w" || team == "b"
        Application::new_game(team.to_sym)
      end
      Application::print
      input = ""
      until input == "quit" || input == "q" || input == "exit" do
        unless input == ""
          Application::current_game.human_move(input)
          Application::current_game.make_move
        end
        print "where would you like to move?  "
        input = gets.chomp
      end
      puts "Thanks for playing!  See you soon."
    end


  end
end