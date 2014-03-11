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
 
module Chess
  module Attack  # Mixin module for use with Board object.  Provides methods for determining if a given square is attacked,
  # and for listing attackers available to each side in a battle over control of a given square.  Lists of attacking pieces
  # are used to perform Static Exchange Evaluation (SEE) during search.

    def king_attacked?(location, attacker_color)        
      attacked_by_regular_piece?(location, attacker_color)  # kings cannot be attacked by other kings.
    end

    # Determine if given square is attacked by any piece of the specified color, including the enemy king.
    def attacked?(location, attacker_color) 
      attacked_by_regular_piece?(location, attacker_color) ||
      single_attack?(location, Pieces::PIECES_BY_COLOR[attacker_color][:K], Pieces::DIRECTIONS[:ray]) # king attacks
    end

    # Determine if given square is attacked by any non-king piece of the specified color.
    def attacked_by_regular_piece?(location, attacker_color) 
      pieces = Pieces::PIECES_BY_COLOR[attacker_color]
      knight, bishop, rook, queen = pieces[:N], pieces[:B], pieces[:R], pieces[:Q]

      attacked_by_pawn?(location, attacker_color) || # pawn attacks
      ray_attack?(location, rook, queen, Pieces::DIRECTIONS[:straight]) || # queen and rook attacks
      ray_attack?(location, bishop, queen, Pieces::DIRECTIONS[:diagonal]) || # queen and bishop attacks
      single_attack?(location, knight, Pieces::DIRECTIONS[:N]) # knight attacks
    end

    # Check for attacks by enemy pawns.
    def attacked_by_pawn?(location, attacker_color)
      if attacker_color == :w   
        return true if self[location + Pieces::SE] == :wP || self[location + Pieces::SW] == :wP
      else
        return true if self[location + Pieces::NE] == :bP || self[location + Pieces::NW] == :bP
      end
      false
    end

    # Check for attacks by sliding pieces (bishops, rooks, queens).  
    def ray_attack?(location, threat_piece, queen, directions)
      directions.each { |vector| return true if ray_attack_direction?(location, threat_piece, queen, vector) }
      false
    end

    # Repeatedly add an increment vector to location, scanning along a direction 
    # until either a threat piece is detected or movement is blocked.
    def ray_attack_direction?(location, threat_piece, queen, vector) 
      square = location + vector 
      while self.on_board?(square)
        return self[square] == threat_piece || self[square] == queen unless self.empty?(square)
        square += vector
      end
      false
    end

    # Check for attacks by pieces that move in a single jump (knights and kings).
    def single_attack?(location, threat_piece, directions)  
      directions.each { |vector| return true if self[location + vector] == threat_piece }
      return false
    end

    # Create lists of all pieces that can attack the given square during an exchange.  This includes 'hidden'
    # attackers that must wait until another piece of their color has been exchanged before attacking.
    def get_square_attackers(location)
      { w: get_square_attackers_by_color(location, :w), b: get_square_attackers_by_color(location, :b) }
    end

    def get_square_attackers_by_color(location, color)
      pieces, attackers = Pieces::PIECES_BY_COLOR[color], []
      knight, bishop, rook, queen, king = pieces[:N], pieces[:B], pieces[:R], pieces[:Q], pieces[:K]

      get_pawn_attackers(attackers, location, color) # pawns
      get_ray_attackers(attackers, location, rook, queen, Pieces::DIRECTIONS[:straight]) # queens and rooks
      get_ray_attackers(attackers, location, bishop, queen, Pieces::DIRECTIONS[:diagonal]) # queens and bishops
      get_single_attackers(attackers, location, knight, Pieces::DIRECTIONS[:N]) # knights
      get_single_attackers(attackers, location, king, Pieces::DIRECTIONS[:ray]) # kings
      return attackers
    end

    # Add any available pawns (bishops, rooks, queens) to attackers array.  If an attacking pawn is found,
    # this method continues scanning along the direction of attack to find any hidden sliding piece attackers.
    def get_pawn_attackers(attackers, location, color)
      if color == :w
        square = location + Pieces::SE
        if self[square] == :wP
          insert_attacker(attackers, square)
          get_ray_attackers_by_direction(attackers, square, :wB, :wQ, Pieces::SE ) # check for 'hidden' attackers 
        end
        square = location + Pieces::SW
        if self[square] == :wP
          insert_attacker(attackers, square)
          get_ray_attackers_by_direction(attackers, square, :wB, :wQ, Pieces::SW ) # check for 'hidden' attackers 
        end
      else
        square = location + Pieces::NE
        if self[square] == :bP
          insert_attacker(attackers, square)
          get_ray_attackers_by_direction(attackers, square, :bB, :bQ, Pieces::NE ) # check for 'hidden' attackers 
        end
        square = location + Pieces::NW
        if self[square] == :bP
          insert_attacker(attackers, square)
          get_ray_attackers_by_direction(attackers, square, :bB, :bQ, Pieces::NW ) # check for 'hidden' attackers 
        end
      end
    end

    # Add any available sliding pieces (bishops, rooks, queens) to attackers array. 
    def get_ray_attackers(attackers, location, threat_piece, queen, directions)
      directions.each { |vector| get_ray_attackers_by_direction(attackers, location, threat_piece, queen, vector) }
    end

    # Repeatedly add an increment vector to location, scanning along a direction and inserting any available 
    # sliding attack pieces into the attackers array.
    def get_ray_attackers_by_direction(attackers, location, threat_piece, queen, vector, blocking_square=nil)
      square = location + vector
      while self.on_board?(square)
        unless self.empty?(square)                                 # If square is occupied, it's either a threat piece, 
          if self[square] == threat_piece || self[square] == queen # a non-attacker of same color, or a piece of opposite color.
            if blocking_square     
              insert_hidden_attacker(attackers, square, blocking_square)
            else
              insert_attacker(attackers, square)
            end
            blocking_square = square
          else
            break  # if occupied by non-threat piece, stop searching this direction
          end
        end
        square += vector
      end
    end

    def get_single_attackers(attackers, location, threat_piece, directions)
      directions.each do |vector|
        insert_attacker(attackers, location + vector) if self[location + vector] == threat_piece
      end  # knights and kings cannot block other attackers.
    end

    # Insertion sort.  Keeps attackers sorted in order of value at risk (less expensive pieces first).
    def insert_attacker(attackers, square, insert_index=0)
      if attackers.empty?
        attackers << square
      else
        square_value = Pieces::PIECE_SYM_ID[self[square]]
        max = attackers.count - 1
        (insert_index..max).each do |i|
          break if Pieces::PIECE_SYM_ID[self[attackers[i]]] >= square_value
          insert_index += 1
        end
        attackers.insert(insert_index, square)
      end
    end

    # Hidden attackers must come after the piece by which they are blocked, but are otherwise sorted normally.
    def insert_hidden_attacker(attackers, square, blocking_square) 
      insert_index, max = 0, attackers.count - 1
      (0..max).each do |i|
        break if attackers[i] == blocking_square
        insert_index += 1
      end
      insert_attacker(attackers, square, insert_index) # normal iterative insertion sort.
    end

  end
end

























