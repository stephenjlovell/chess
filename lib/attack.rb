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
 
module Application
  module Attack  # Mixin module for use with Board object.

    def king_attacked?(location, attacker_color)
      pieces = Pieces::PIECES_BY_COLOR[attacker_color]
      knight, bishop, rook, queen, king = pieces[:N], pieces[:B], pieces[:R], pieces[:Q], pieces[:K]

      attacked_by_pawn?(location, attacker_color) || # pawns
      ray_attack?(location, rook, queen, Pieces::DIRECTIONS[:straight]) || # queens and rooks
      ray_attack?(location, bishop, queen, Pieces::DIRECTIONS[:diagonal]) || # queens and bishops
      single_attack?(location, knight, Pieces::DIRECTIONS[:N]) # knights
      # king cannot be attacked by another king.
    end

    def attacked?(location, attacker_color)
      pieces = Pieces::PIECES_BY_COLOR[attacker_color]
      knight, bishop, rook, queen, king = pieces[:N], pieces[:B], pieces[:R], pieces[:Q], pieces[:K]

      attacked_by_pawn?(location, attacker_color) || # pawns
      ray_attack?(location, rook, queen, Pieces::DIRECTIONS[:straight]) || # queens and rooks
      ray_attack?(location, bishop, queen, Pieces::DIRECTIONS[:diagonal]) || # queens and bishops
      single_attack?(location, knight, Pieces::DIRECTIONS[:N]) || # knights
      single_attack?(location, king, Pieces::DIRECTIONS[:ray])  # Kings
    end

    def attacked_by_pawn?(location, attacker_color)
      if attacker_color == :w   
        return true if self[location + Pieces::SE] == :wP
        return true if self[location + Pieces::SW] == :wP
      else
        return true if self[location + Pieces::NE] == :bP
        return true if self[location + Pieces::NW] == :bP
      end
      return false
    end

    def ray_attack?(location, threat_piece, queen, directions)
      directions.each { |vector| return true if ray_attack_direction?(location, threat_piece, queen, vector) }
      return false
    end

    def ray_attack_direction?(location, threat_piece, queen, vector)
      square = location + vector
      while self.on_board?(square)
        unless self.empty?(square)
          return self[square] == threat_piece || self[square] == queen
        end
        square += vector
      end
      return false
    end

    def single_attack?(location, threat_piece, directions)
      directions.each { |vector| return true if self[location + vector] == threat_piece }
      return false
    end

    def get_square_attackers(location)
      { w: get_square_attackers_by_color(location, :w),
        b: get_square_attackers_by_color(location, :b) }
    end

    def get_square_attackers_by_color(location, color)
      pieces = Pieces::PIECES_BY_COLOR[color]
      knight, bishop, rook, queen, king = pieces[:N], pieces[:B], pieces[:R], pieces[:Q], pieces[:K]

      attackers = []
      get_pawn_attackers(attackers, location, color) # pawns
      get_ray_attackers(attackers, location, rook, queen, Pieces::DIRECTIONS[:straight]) # queens and rooks
      get_ray_attackers(attackers, location, bishop, queen, Pieces::DIRECTIONS[:diagonal]) # queens and bishops
      get_single_attackers(attackers, location, knight, Pieces::DIRECTIONS[:N]) # knights
      get_single_attackers(attackers, location, threat_piece, king, Pieces::DIRECTIONS[:ray]) # kings
      return attackers
    end

    def get_pawn_attackers(attackers, location, color)


    end

    def get_ray_attackers(attackers, location, threat_piece, queen, directions)


    end

    def get_ray_attackers_by_direction(attackers, location, threat_piece, queen, vector)


    end

    def get_single_attackers(attackers, location, threat_piece, directions)


    end

    def insert_and_sort(attackers, square)


    end



  end
end

























