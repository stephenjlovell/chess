
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

      def explore_direction(start, direction, color, board, moves = [] )
        new_pos = [ start[0] + direction[0], start[1] + direction[1] ]
        if pseudo_legal?(new_pos[0],new_pos[1], color, board)
          moves << new_pos
          if move_until_blocked? && !board.enemy?(new_pos[0], new_pos[1], color)
            explore_direction(new_pos, direction, color, board, moves) 
          end
        end
        return moves
      end
    end

  end
end


# basic movement pattern:

# for each direction of movement:
#   position += direction
#   check if move position is pseudo-legal
#   if legal, add position to list of possible moves
#   if move_until_blocked, recursively call inspect_direction until blocked by friendly piece or capture results
#   























