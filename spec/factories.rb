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

FactoryGirl.define do

  factory :game, class: Application::Game do

  end

  factory :location, class: Application::Location::Location do
    r 0
    c 0
    initialize_with { new(r,c) }
  end

  factory :board, class: Application::Board do  
    squares SQUARES
  end

  factory :position, class: Application::Position::ChessPosition do
    board  { FactoryGirl.build(:board) }
    pieces { Application::Pieces::setup(board) }
    side_to_move :w
    initialize_with { new(board, pieces, side_to_move) }
  end



end
