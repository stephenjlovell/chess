
module Application

  class PiecePosition
    attr_reader :x
    attr_reader :y

    def initialize(x,y)
      set(x,y)
    end

    def set(x,y)
      @x = x
      @y = y
    end

  end

  class ChessPosition
    def setup_pieces(board)
      @pieces = []
      board.each_with_index do |row, y|
        row.each_with_index do |sym, x|
          unless sym == nil || sym == :XX
            @pieces << Pieces::create_piece_by_sym(sym,x,y) 
          end
        end
      end
    end
  end

end