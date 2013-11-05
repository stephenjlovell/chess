module Application
  module Movement
    COLUMNS = { 2 => "a", 3 => "b", 4 => "c", 5 => "d", 6 => "e", 7 => "f", 8 => "g", 9 => "h" }


    class Move
      attr_reader :position, :coordinates, :target, :capture_value, :en_passant

      def initialize(position, coordinates, target, capture_value, options = {})
        @position = position
        @coordinates = coordinates
        @target = target
        @capture_value = capture_value
        @options = options
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

      if move.options[:en_passant_capture]
        b[piece.position[0], move.target[1]] = nil
        p[side_to_move].delete(coordinates(piece.position[0], move.target[1]))
        p.en_passant_target = nil
      elsif move.options[:en_passant_target]
        p.en_passant_target = move.target
      end

      piece.position = move.target
    end

    def self.castle!
      # handle castling
    end


  end
end



