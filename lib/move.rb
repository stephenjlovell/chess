
module Application
  module Movement 
    # define types of movement that can be mixed in to the piece classes.
    #
    class << self
    #   PAWN_ATTACK = [[1,1],[1,-1]]
    #   PAWN_ADVANCE = [[1,0]]
    #   PAWN_INITIAL_ADVANCE = [[1,0],[2,0]]
    #   DIAGONALS = [[1,1],[1,-1],[-1,1],[-1,-1]]
    #   SQUARES = [[1,0],[-1,0],[0,1],[0,-1]]

      def pseudo_legal?(row, column, color, board)
        if board.out_of_bounds?(row, column) 
          false
        elsif board.empty?(row, column)
          true
        elsif  board.enemy?(row, column, color)
          true
        else
          false
        end
      end

    end


  end
end