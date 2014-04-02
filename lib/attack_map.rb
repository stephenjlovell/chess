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

  # During move generation, the 'to' and 'from' squares are compared to the attack maps for each color 
  # to determine if the move gives check or evades check, and to update the attack maps if needed.

  # Responsibility for tracking king location will be shifted to this class.

  class KingAttackMap
    attr_accessor :king_location
    attr_reader :threat_direction

    def initialize(position, color, king_location)
      @map = {}
      @color = color
      @king_location = king_location
      @threat_direction = nil
    end

    def in_check?
      !@threat_direction.nil?
    end

    def on_map?(square)
      @map.has_key?(square)
    end

    # Determine orientation of the given attack map square relative to king location. Only used for sliding pieces.
    def direction_from_king(square)
      if @king_location.r < square.r 
        if @king_location.c < square.c
          Pieces::NE
        elsif @king_location.c == square.c
          Pieces::NORTH
        else
          Pieces::NW
        end
      elsif @king_location.r == square.r
        if @king_location.c < square.c
          Pieces::EAST
        elsif @king_location.c == square.c
          # king capture
        else
          Pieces::WEST
        end
      else
        if @king_location.c < square.c
          Pieces::SE
        elsif @king_location.c == square.c
          Pieces::SOUTH
        else
          Pieces::SW
        end
      end
    end



    # Check if either the 'to' or 'from' square is in the attack map for the current side to move.  Update 
    # the attack map if needed.
    def own_move_update(move)
      is_from = on_map?(move.from)
      is_to = on_map?(move.to)

      if is_from && is_to

      elsif is_from
        vector = direction_from_king(move.from)

      elsif is_to
        vector = direction_from_king(move.to)

      end

    end

    # Check if the 'to' or 'from' square is in the enemy attack map. If found, update the attack map.
    def enemy_move_update(move)
      is_from = on_map?(move.from)
      is_to = on_map?(move.to)

      if is_from && is_to

      elsif is_from
        vector = direction_from_king(move.from)

      elsif is_to
        vector = direction_from_king(move.to)

      end

      # # save the threat direction for use in generating check evasions.
      # @threat_direction = direction_from_king(move.to)

    end



    # When an enemy piece moves onto the map, determine if the piece moved is a threat to the 
    # enemy king.
    def gives_check?(move)
      if on_map?(move.to)



      end
    end

    # Determine if a move to this square would get the king out of check.
    def evades_check?(move)
      if on_map?(move.to)

      end
    end


    private

    # Used to build new attack maps for a newly instantiated position objects. Also used to re-calculate
    # the map on king movement.
    def generate_attack_map(king_location)

    end

  end



end








