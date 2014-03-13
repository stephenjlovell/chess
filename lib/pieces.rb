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
# CONORTH_NECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#-----------------------------------------------------------------------------------

module Chess
  module Pieces

    # Assign each piece a base material value approximating its relative importance.      
    PIECE_VALUES = { P: 100, N: 320, B: 333, R: 510, Q: 880, K: 100000 }

    # This constant represents the maximum value of all non-king pieces for each side.
    NON_KING_VALUE = PIECE_VALUES[:P]*8 + PIECE_VALUES[:N]*2 + PIECE_VALUES[:B]*2 + 
                     PIECE_VALUES[:R]*2 + PIECE_VALUES[:Q]

    # When a player has lost 2/3 of their pieces by value, they are considered to be in the 'endgame'.  
    # Endgame state is used during Evaluation.
    ENDGAME_VALUE = PIECE_VALUES[:K] + NON_KING_VALUE/3

    # During search, an evaluation score less than KING_LOSS indicates that the king will be captured in the next ply.  This
    # is used to avoid illegal moves without the overhead cost of checking each possible move for full legality.
    KING_LOSS = NON_KING_VALUE - PIECE_VALUES[:K] 

    # This constant provides a finite evaluation score indicating checkmate.   
    MATE = NON_KING_VALUE + PIECE_VALUES[:K]

    # This hash associates piece symbols with their underlying color.
    PIECE_COLOR = { wP: :w, wN: :w, wB: :w, wR: :w, wQ: :w, wK: :w,
                    bP: :b, bN: :b, bB: :b, bR: :b, bQ: :b, bK: :b }

    # This hash associates each color with its corresponding set of piece symbols.
    PIECES_BY_COLOR = { w: { P: :wP, N: :wN, B: :wB, R: :wR, Q: :wQ, K: :wK }, 
                        b: { P: :bP, N: :bN, B: :bB, R: :bR, Q: :bQ, K: :bK } }

    PIECE_ID = { P: 1, N: 2, B: 3, R: 4, Q: 5, K: 6 } # Used for move ordering by MVV-LVA heuristic.
    
    # This hash associates each piece symbol with the ID of the underlying piece type.
    PIECE_SYM_ID = { wP: PIECE_ID[:P], wN: PIECE_ID[:N], wB: PIECE_ID[:B], wR: PIECE_ID[:R], wQ: PIECE_ID[:Q], wK: PIECE_ID[:K],
                     bP: PIECE_ID[:P], bN: PIECE_ID[:N], bB: PIECE_ID[:B], bR: PIECE_ID[:R], bQ: PIECE_ID[:Q], bK: PIECE_ID[:K] }


    # Increment vectors used for move generation:
    NORTH = [1,0]
    NE = [1,1]
    EAST = [0,1]
    SE = [-1,1]
    SOUTH = [-1,0]
    SW = [-1,-1]
    WEST = [0,-1]
    NW = [1,-1]
    NORTH_NW = [2,-1]
    NORTH_NE = [2,1]
    EAST_NE = [1,2]
    EAST_SE = [-1,2]
    SOUTH_SE = [-2,1]
    SOUTH_SW = [-2,-1]
    WEST_SW = [-1,-2]
    WEST_NW = [1,-2]

    DIRECTIONS = { straight: [ NORTH, SOUTH, EAST, WEST ], 
                   diagonal: [ NE, NW, SE, SW ],
                   ray: [ NORTH, NE, EAST, SE, SOUTH, SW, WEST, NW ], 
                   N: [ NORTH_NW, NORTH_NE, EAST_NE, EAST_SE, SOUTH_SE, SOUTH_SW, WEST_SW, WEST_NW ], 
                   P: { w: { attack: [ NE, NW ],
                             advance: NORTH,
                             initial: [2,0],
                             enp_offset: NORTH, 
                             start_row: 3 },
                        b: { attack: [ SE, SW ],
                             advance: SOUTH,                               
                             initial: [-2,0],
                             enp_offset: SOUTH,  
                             start_row: 8 }, 
                        en_passant: [ EAST, WEST ] } }


    # The Piece class provides an abstract template and shared behavior for concrete piece classes.
    class Piece  
      attr_reader :color, :symbol

      def initialize(color)
        @color = color
        @symbol = (@color.to_s + self.class.type.to_s).to_sym
      end

      def to_s
        @symbol.to_s
      end

      # Generate all pseudo-legal moves available to the current piece.
      # Moves are pushed into separate arrays for captures, promotions, promotion captures, and other moves.
      def get_moves(position, from, moves, captures, promotions, promotion_captures) 
        self.class.directions.each { |vector| get_moves_for_direction(position, position.board, from, vector, moves, captures) }
      end

      # Generate all pseudo-legal capture moves available to the current piece.
      # Moves are pushed into separate arrays for captures and promotion captures.
      def get_captures(position, from, captures, promotion_captures)
        self.class.directions.each { |vector| get_captures_for_direction(position, position.board, from, vector, captures) }
      end

      private 

      # Scan along a direction by repeatedly adding a given increment vector to the current square.
      # Add a move object of the appropriate type to the move array if the square is a valid destination.
      def get_moves_for_direction(position, board, from, vector, moves, captures)
        to = from + vector
        while board.on_board?(to)
          if board.empty?(to)
            moves << Move::Factory.build(self, from, to, :regular_move)
          else
            if board.enemy?(to, @color)
              raise Memory::HashCollisionError if position.enemy_pieces[to].nil?   
              captures << Move::Factory.build(self, from, to, :regular_capture, position.enemy_pieces[to])
            end
            break  # if path blocked by any piece, stop evaluating in this direction.
          end
          to += vector
        end
      end

      # Scan along a direction by repeatedly adding a given increment vector to the current square.
      # Add a move object of the appropriate type to the move array if the square is a valid capture target.
      def get_captures_for_direction(position, board, from, vector, captures)
        to = from + vector
        while board.on_board?(to)
          if board.occupied?(to) 
            if board.enemy?(to, @color)
              raise Memory::HashCollisionError if position.enemy_pieces[to].nil?              
              captures << Move::Factory.build(self, from, to, :regular_capture, position.enemy_pieces[to])
            end
            break # if path blocked by any piece, stop evaluating in this direction.
          end
          to += vector
        end
      end

    end

    class Pawn < Piece
      class << self
        VALUE = PIECE_VALUES[:P]
        def value
          VALUE
        end

        ID = PIECE_ID[:P]
        def id
          ID
        end

        def type
          :P
        end

        PAWN_DIRECTIONS = DIRECTIONS[:P]
        def directions
          PAWN_DIRECTIONS
        end
      end

      def get_moves(position, from, moves, captures, promotions, promotion_captures) 
        get_attacks(position, position.board, from, captures, promotion_captures)
        get_en_passant(position, position.board, from, captures) if position.enp_target
        get_advances(position, position.board, from, moves, promotions)
      end

      def get_captures(position, from, captures, promotion_captures)         
        get_attacks(position, position.board, from, captures, promotion_captures)
        get_en_passant(position, position.board, from, captures) if position.enp_target
      end

      private

      # Add any valid regular pawn attacks to move array. Pawns may only attack toward the enemy side.
      def get_attacks(position, board, from, captures, promotion_captures)
        self.class.directions[@color][:attack].each do |vector|  # normal attacks
          to = from + vector
          if board.enemy?(to, @color)
            enemy = position.enemy_pieces[to]
            if to.r == ENEMY_BACK_ROW[@color] # determine if pawn promotion
              promotion_captures << Move::Factory.build(self, from, to, :pawn_promotion_capture, enemy)
            else
              captures << Move::Factory.build(self, from, to, :regular_capture, enemy)
            end
          end
        end
      end

      # Add any valid En-Passant captures to move array. Any pawn that made a double move from
      # its starting row on the previous turn is vulnerable to an En-Passant attack by the opposing side.
      def get_en_passant(position, board, from, captures)
        self.class.directions[:en_passant].each do |vector|
          target = from + vector
          if position.enp_target == target
            offset = self.class.directions[@color][:enp_offset]
            to = target + offset
            enemy = position.enemy_pieces[target]
            captures << Move::Factory.build(self, from, to, :enp_capture, enemy, target)
          end
        end
      end

      # Add any valid non-capture moves to move array, including promotions and double moves (En-Passant advances).
      def get_advances(position, board, from, moves, promotions)
        dir = self.class.directions[@color]
        to = from + dir[:advance]
        if board.empty?(to)
          if to.r == ENEMY_BACK_ROW[@color] # determine if pawn promotion
            promotions << Move::Factory.build(self, from, to, :pawn_promotion, @color)
          else
            moves << Move::Factory.build(self, from, to, :regular_move)
          end
          if from.r == dir[:start_row]
            to = from + dir[:initial]
            if board.empty?(to)
              moves << Move::Factory.build(self, from, to, :enp_advance)
            end
          end
        end
      end

    end

    class Knight < Piece
      class << self
        VALUE = PIECE_VALUES[:N]
        def value
          VALUE
        end

        ID = PIECE_ID[:N]
        def id
          ID
        end

        def type
          :N
        end

        KNIGHT_DIRECTIONS = DIRECTIONS[:N]
        def directions
          KNIGHT_DIRECTIONS
        end
      end

      # Generate all pseudo-legal moves available to the current knight.
      # Moves are pushed into separate arrays for captures, promotions, promotion captures, and other moves.
      def get_moves(position, from, moves, captures, promotions, promotion_captures)              
        board = position.board
        self.class.directions.each do |vector|
          to = from + vector
          if board.empty?(to)
            moves << Move::Factory.build(self, from, to, :regular_move)
          else
            if board.enemy?(to, @color)
              captures << Move::Factory.build(self, from, to, :regular_capture, position.enemy_pieces[to])
            end
          end
        end
      end

      # Generate all pseudo-legal capture moves available to the current knight.
      # Moves are pushed into separate arrays for captures and promotion captures.
      def get_captures(position, from, captures, promotion_captures)
        board = position.board
        self.class.directions.each do |vector|
          to = from + vector
          if board.enemy?(to, @color)
            captures << Move::Factory.build(self, from, to, :regular_capture, position.enemy_pieces[to])
          end
        end
      end
    end

    class Bishop < Piece
      class << self
        VALUE = PIECE_VALUES[:B]
        def value
          VALUE
        end

        ID = PIECE_ID[:B]
        def id
          ID
        end

        def type
          :B
        end

        BISHOP_DIRECTIONS = DIRECTIONS[:diagonal]
        def directions
          BISHOP_DIRECTIONS
        end
      end
    end

    class Rook < Piece
      class << self
        VALUE = PIECE_VALUES[:R]
        def value
          VALUE
        end

        ID = PIECE_ID[:R]
        def id
          ID
        end

        def type
          :R
        end

        ROOK_DIRECTIONS = DIRECTIONS[:straight]
        def directions
          ROOK_DIRECTIONS
        end
      end
    end

    class Queen < Piece
      class << self
        VALUE = PIECE_VALUES[:Q]
        def value
          VALUE
        end

        ID = PIECE_ID[:Q]
        def id
          ID
        end

        def type
          :Q
        end

        QUEEN_DIRECTIONS = DIRECTIONS[:diagonal] + DIRECTIONS[:straight]
        def directions
          QUEEN_DIRECTIONS
        end
      end
    end

    class King < Piece
      class << self
        VALUE = PIECE_VALUES[:K]
        def value
          VALUE
        end

        ID = PIECE_ID[:K]
        def id
          ID
        end

        def type
          :K
        end

        KING_DIRECTIONS = DIRECTIONS[:diagonal] + DIRECTIONS[:straight]
        def directions
          KING_DIRECTIONS
        end
      end

      # Generate all pseudo-legal moves available to the current king.
      # Moves are pushed into separate arrays for captures, promotions, promotion captures, and other moves.
      def get_moves(position, from, moves, captures, promotions, promotion_captures)   
        board = position.board
        self.class.directions.each do |vector|
          to = from + vector
          if board.empty?(to)
            moves << Move::Factory.build(self, from, to, :king_move)
          elsif board.enemy?(to, @color)
            captures << Move::Factory.build(self, from, to, :king_capture, position.enemy_pieces[to])
          end
        end
      end

      # Generate all pseudo-legal capture moves available to the current king.
      # Moves are pushed into separate arrays for captures and promotion captures.
      def get_captures(position, from, captures, promotion_captures) 
        board = position.board
        self.class.directions.each do |vector|
          to = from + vector
          if board.enemy?(to, @color)
            captures << Move::Factory.build(self, from, to, :king_capture, position.enemy_pieces[to])
          end
        end
      end
    end

    # This hash associates piece symbols with the value of their piece type.
    PIECE_SYM_VALUES = { wP: PIECE_VALUES[:P], wN: PIECE_VALUES[:N], wB: PIECE_VALUES[:B], 
                         wR: PIECE_VALUES[:R], wQ: PIECE_VALUES[:Q], wK: PIECE_VALUES[:K],
                         bP: PIECE_VALUES[:P], bN: PIECE_VALUES[:N], bB: PIECE_VALUES[:B], 
                         bR: PIECE_VALUES[:R], bQ: PIECE_VALUES[:Q], bK: PIECE_VALUES[:K] }

    def self.get_value_by_sym(sym)
      return 0 if sym == nil || sym == :XX
      PIECE_SYM_VALUES[sym]
    end

  end
end

