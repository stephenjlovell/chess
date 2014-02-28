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

require 'spec_helper'

describe Chess::Search do

  before do 
    @s = Chess::Search
    @depth = 4
  end

  describe "permits use of" do
    let(:game) { FactoryGirl.build(:test_game) }
    let(:pos) { game.position }

    describe "mtdf" do
      # it "from within an iterative deepening framework" do
      #   puts "iterative_deepening_mtdf \n #{@s::select_move(pos, @depth) { @s::iterative_deepening_mtdf }[0] }"
      # end
      # it "_step from within an iterative deepening framework" do
      #   puts "iterative_deepening_mtdf_step \n #{@s::select_move(pos, @depth) { @s::iterative_deepening_mtdf_step }[0] }"
      #   pos.board.print
      # end
    end
    describe "alpha beta" do
      # it "from within an iterative deepening framework" do
      #   puts "iterative_deepening_alpha_beta \n #{@s::select_move(pos, @depth) { @s::iterative_deepening_alpha_beta }[0] }"
      # end
    end
  end

  # describe "static exchange evaluation" do
  #   let(:loc) { Chess::Location::get_location(5,6) }
  #   let(:see_pos) { FactoryGirl.build(:see_position) }
  #   it "should correctly value an exchange over a single square" do
  #     see_pos.board.print
  #     @s.get_see_score(see_pos, loc).should == 100
  #   end
  # end

  # describe "should make tactically sound moves" do
  #   let(:game) { FactoryGirl.build(:game) }
  #   let(:sanity_check) { Chess::Notation::fen_to_position("1nbqkbnr/1ppppppp/8/8/1p1P2P1/8/r1P1PP1P/RNBQKBNR w KQk - 0 1") }
  #   let(:puzzle) { Chess::Notation::epd_to_position('1rbq1rk1/p1b1nppp/1p2p3/8/1B1pN3/P2B4/1P3PPP/2RQ1R1K w - - bm Nf6+; id "position 01";') }

  #   it do
  #     game.position = sanity_check
  #     @s::select_move(sanity_check,@depth)[0].to_s.should == "a1a2"
  #   end

  # #   # it "should avoid search explosion on more challenging problems" do 
  # #   #   game.position = puzzle
  # #   #   @s::select_move(puzzle, @depth)[0].to_s.should == "e4f6"
  # #   # end

  # end

  describe "playing strength" do
    let(:problems) { load_test_suite('./test_suites/win_at_chess.epd') }
    
    it "should be able to take standardized tests" do
      take_test(problems, @depth, false)
    end
  end

end















