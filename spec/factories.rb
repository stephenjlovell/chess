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

# sets up a board with some useful properties for testing.
SQUARES = [ [ :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX ],  # 0       
            [ :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX ],  # 1    
            [ :XX, :XX, :wR, :wN, :wB, :wQ, :wK, nil, nil, :wR, :XX, :XX ],  # 2    1
            [ :XX, :XX, :wP, :wP, :wP, :wP, nil, :wP, :wP, :wP, :XX, :XX ],  # 3    2
            [ :XX, :XX, nil, nil, :bP, nil, :wP, nil, nil, nil, :XX, :XX ],  # 4    3
            [ :XX, :XX, nil, nil, nil, nil, nil, nil, :bB, nil, :XX, :XX ],  # 5    4
            [ :XX, :XX, nil, nil, nil, nil, nil, nil, nil, nil, :XX, :XX ],  # 6    5
            [ :XX, :XX, nil, nil, nil, :bP, nil, :bN, nil, nil, :XX, :XX ],  # 7    6
            [ :XX, :XX, :bP, :bP, nil, nil, :bP, :bP, :bP, :bP, :XX, :XX ],  # 8    7
            [ :XX, :XX, :bR, :bN, nil, :bQ, :bK, :bB, nil, :bR, :XX, :XX ],  # 9    8
            [ :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX ],  # 10   
            [ :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX ] ] # 11   
      # column  0    1    2    3    4    5    6    7    8    9    10   11
      # letter            A    B    C    D    E    F    G    H

                                                                             # row  board #
INITIAL = [ [ :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX ],  # 0       
            [ :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX ],  # 1    
            [ :XX, :XX, :wR, :wN, :wB, :wQ, :wK, :wB, :wN, :wR, :XX, :XX ],  # 2    1
            [ :XX, :XX, :wP, :wP, :wP, :wP, :wP, :wP, :wP, :wP, :XX, :XX ],  # 3    2
            [ :XX, :XX, nil, nil, nil, nil, nil, nil, nil, nil, :XX, :XX ],  # 4    3
            [ :XX, :XX, nil, nil, nil, nil, nil, nil, nil, nil, :XX, :XX ],  # 5    4
            [ :XX, :XX, nil, nil, nil, nil, nil, nil, nil, nil, :XX, :XX ],  # 6    5
            [ :XX, :XX, nil, nil, nil, nil, nil, nil, nil, nil, :XX, :XX ],  # 7    6
            [ :XX, :XX, :bP, :bP, :bP, :bP, :bP, :bP, :bP, :bP, :XX, :XX ],  # 8    7
            [ :XX, :XX, :bR, :bN, :bB, :bQ, :bK, :bB, :bN, :bR, :XX, :XX ],  # 9    8
            [ :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX ],  # 10   
            [ :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX ] ] # 11   
      # column  0    1    2    3    4    5    6    7    8    9    10   11
      # letter            A    B    C    D    E    F    G    H

FactoryGirl.define do

  factory :clock, class: Application::Clock do
    initialize_with { new(120) }
  end

  factory :transposition_table, class: Application::Memory::TranspositionTable 

  factory :game, class: Application::Game do
    position { FactoryGirl.build(:position) }
    tt { FactoryGirl.build(:transposition_table) }
    clock { FactoryGirl.build(:clock)}
    initialize_with { new(:w, 120) }

    factory :test_game do
      position { FactoryGirl.build(:test_position) }
    end
  end

  factory :position, class: Application::Position::ChessPosition do
    board  { FactoryGirl.build(:board) }
    pieces { Application::Pieces::setup(board) }
    side_to_move :w
    halfmove_clock 0
    hash { self.get_initial_hash }
    initialize_with { new(board, pieces, side_to_move, halfmove_clock) }

    factory :test_position do
      board { FactoryGirl.build(:test_board) }
      pieces { Application::Pieces::setup(board) }
      side_to_move :w
      halfmove_clock 20
      hash { self.get_initial_hash }
      initialize_with { new(board, pieces, side_to_move, halfmove_clock) }
    end
  end

  factory :board, class: Application::Board do  
    squares INITIAL

    factory :test_board do  
      squares SQUARES
    end
  end

  factory :location, class: Application::Location::Location do
    r 0
    c 0
    initialize_with { new(r,c) }
  end

end
