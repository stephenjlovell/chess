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
  module Movement

    COLUMNS = { 2 => "a", 3 => "b", 4 => "c", 5 => "d", 
                6 => "e", 7 => "f", 8 => "g", 9 => "h" }
    class Move
      attr_reader :position, :coordinates, :target, :capture_value, 
                  :en_passant, :options

      def initialize(position, coordinates, target, capture_value, options = {})
        @position = position
        @coordinates = coordinates
        @target = target
        @capture_value = capture_value
        @options = options
      end

      def to_s
        piece = @position.pieces[@position.side_to_move][@coordinates]
        "#{piece.symbol.to_s} #{@coordinates} to #{Movement::coordinates(@target[0], @target[1])}"
      end

    end

    def self.coordinates(row,column)
      (COLUMNS[row]) + (column - 1).to_s
    end



    def self.castle!
      # handle castling
    end


  end
end



