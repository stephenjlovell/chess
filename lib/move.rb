module Application
  module Movement
    COLUMNS = { 2 => "a", 3 => "b", 4 => "c", 5 => "d", 6 => "e", 7 => "f", 8 => "g", 9 => "h" }


    class Move
      attr_reader :position, :coordinates, :target, :capture_value, :en_passant

      def initialize(position, coordinates, target, capture_value, en_passant)
        @position = position
        @coordinates = coordinates
        @target = target
        @capture_value = capture_value
        @en_passant = en_passant
      end

    end


    def self.coordinates(row,column)
      (COLUMNS[row]) + (column - 1).to_s
    end

    def self.move!(move)  # where do we get the color?
      p, b = move.position, move.position.board
      piece = p[p.side_to_move][move.coordinates]

      b[move.target[0],move.target[1]] = b[piece.position[0],piece.position[1]]
      b[piece.position[0],piece.position[1]] = nil
      
      new_coordinates = coordinates(move.target[0],move.target[1])
      p[p.side_to_move][new_coordinates] = piece
      p[p.side_to_move].delete(move.coordinates)

      if p.en_passant  # handle en passant captures
        b[piece.position[0], move.target[1]] = nil
        en_passant_target = coordinates(piece.position[0], move.target[1])
        p[side_to_move].delete(en_passant_target)
      end

      piece.position = move.target[]
    end

    def self.castle!

    end


  end
end



