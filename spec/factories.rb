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
