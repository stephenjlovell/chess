module Application
  module Evaluation
    # this module will contain all helper methods related to determining the heuristic value of
    # a given chess position.

    def self.evaluate(position) # return heuristic value of specified position.
      friend = position.side_to_move
      enemy = friend == :w ? :b : :w
      return net_raw_material(position,friend, enemy)
    end

    def self.net_raw_material(position, friend, enemy)
      raw_material(position, friend) - raw_material(position, enemy)
    end

    def self.raw_material(position, side) # =~ 1,040 at start
      position.pieces[side].inject(0.0) { |total, (key, piece)| total += piece.value }  
    end


    # add reversible Piece-Square Tables








  end
end 




