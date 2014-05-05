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

# an empty board with no pieces, only out-of-bounds symbols.
EMPTY = Array.new(64, 0)

# the initial chess position at start of a new game
id = Chess::Pieces::PIECE_ID     
INITIAL = [ id[:wR], id[:wN], id[:wB], id[:wQ], id[:wK], id[:wB], id[:wN], id[:wR],  # 1 row
            id[:wP], id[:wP], id[:wP], id[:wP], id[:wP], id[:wP], id[:wP], id[:wP],  # 2  
                  0,       0,       0,       0,       0,       0,       0,       0,  # 3    
                  0,       0,       0,       0,       0,       0,       0,       0,  # 4    
                  0,       0,       0,       0,       0,       0,       0,       0,  # 5    
                  0,       0,       0,       0,       0,       0,       0,       0,  # 6    
            id[:bP], id[:bP], id[:bP], id[:bP], id[:bP], id[:bP], id[:bP], id[:bP],  # 7    
            id[:bR], id[:bN], id[:bB], id[:bQ], id[:bK], id[:bB], id[:bN], id[:bR] ] # 8 
        # col     A        B        C        D        E        F        G        H

# # sets up a board with some useful properties for testing.
# SQUARES = [ [ :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX ],  # 0       
#             [ :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX ],  # 1    
#             [ :XX, :XX, :wR, :wN, :wB, :wQ, :wK, 0, 0, :wR, :XX, :XX ],  # 2    1
#             [ :XX, :XX, :wP, :wP, :wP, :wP, 0, :wP, :wP, :wP, :XX, :XX ],  # 3    2
#             [ :XX, :XX, 0, 0, :bP, 0, :wP, 0, 0, 0, :XX, :XX ],  # 4    3
#             [ :XX, :XX, 0, 0, 0, 0, 0, 0, :bB, 0, :XX, :XX ],  # 5    4
#             [ :XX, :XX, 0, 0, 0, 0, 0, 0, 0, 0, :XX, :XX ],  # 6    5
#             [ :XX, :XX, 0, 0, 0, :bP, 0, :bN, 0, 0, :XX, :XX ],  # 7    6
#             [ :XX, :XX, :bP, :bP, 0, 0, :bP, :bP, :bP, :bP, :XX, :XX ],  # 8    7
#             [ :XX, :XX, :bR, :bN, 0, :bQ, :bK, :bB, 0, :bR, :XX, :XX ],  # 9    8
#             [ :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX ],  # 10   
#             [ :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX ] ] # 11   
#       # column  0    1    2    3    4    5    6    7    8    9    10   11
#       # letter            A    B    C    D    E    F    G    H

# # used for testing Static Exchange Evaluation                                 # row  board #
SEE_TEST =  [ id[:wK], 0,       0,      0, id[:wR],       0, 0, id[:wB],   # 2 1
                    0, 0,       0,id[:wN],       0,       0, 0,       0, # 3 2
                    0, 0,       0,      0,       0, id[:wP], 0,       0,  # 4 3
                    0, 0,       0,      0, id[:bP],       0, 0,       0,   # 5 4
                    0, 0, id[:bN],      0,       0, id[:bP], 0,       0,   # 6 5
                    0, 0,       0,      0,       0,       0, 0,       0,  # 7 6
                    0, 0,       0,      0,       0,       0, 0,       0,  # 8 7
              id[:bK], 0,       0,      0, id[:bR],       0, 0,       0 ]  # 9 8
      # column  0    1    2    3    4    5    6    7    8    9    10   11
      # letter            A    B    C    D    E    F    G    H

# # used for testing king safety methods.
# CHECK = [ [ :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX ],  # 0       
#           [ :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX ],  # 1    
#           [ :XX, :XX, :wR, :wN, :wB, :wQ, :wK, 0, 0, :wR, :XX, :XX ],  # 2    1
#           [ :XX, :XX, :wP, :wP, :wP, :wP, 0, 0, :wP, :wP, :XX, :XX ],  # 3    2
#           [ :XX, :XX, 0, 0, :bP, 0, :wP, 0, 0, 0, :XX, :XX ],  # 4    3
#           [ :XX, :XX, :wB, 0, 0, 0, 0, 0, 0, :bB, :XX, :XX ],  # 5    4
#           [ :XX, :XX, 0, 0, 0, 0, 0, 0, 0, 0, :XX, :XX ],  # 6    5
#           [ :XX, :XX, 0, 0, 0, :bP, 0, :bN, 0, 0, :XX, :XX ],  # 7    6
#           [ :XX, :XX, :bP, :bP, 0, 0, :bP, :bP, :bP, :bP, :XX, :XX ],  # 8    7
#           [ :XX, :XX, :bR, :bN, 0, :bQ, :bK, :bB, 0, :bR, :XX, :XX ],  # 9    8
#           [ :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX ],  # 10   
#           [ :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX, :XX ] ] # 11   
#     # column  0    1    2    3    4    5    6    7    8    9    10   11
#     # letter            A    B    C    D    E    F    G    H

FactoryGirl.define do

  factory :clock, class: Chess::Clock do
    initialize_with { new(Chess::TIME_LIMIT) }
  end

  factory :transposition_table, class: Chess::Memory::TranspositionTable 

  factory :game, class: Chess::Game do
    position { FactoryGirl.build(:position) }
    clock { FactoryGirl.build(:clock)}
    initialize_with { new(:w, Chess::TIME_LIMIT) }

    factory :test_game do
      position { FactoryGirl.build(:test_position) }
    end
  end

  factory :position, class: Chess::Position do
    board  { FactoryGirl.build(:board) }

    initialize_with { new(board, :w, 0b1111, 0, 0) }

    factory :test_position do
      board { FactoryGirl.build(:test_board) }
    end

    factory :see_position do
      board { FactoryGirl.build(:see_board) }
    end

    factory :check_position do
      board { FactoryGirl.build(:check_board) }
    end
  end

  factory :board, class: Chess::Board do  
    squares INITIAL

    # factory :test_board do  
    #   squares SQUARES
    # end

    # factory :see_board do
    #   squares SEE_TEST
    # end

    # factory :check_board do
    #   squares CHECK
    # end
  end

  factory :location, class: Chess::Location::Location do
    r 0
    c 0
    initialize_with { new(r,c) }
  end

end
