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

  # describe "permits use of Iterative Deepening" do
  #   let(:game) { FactoryGirl.build(:test_game) }
  #   let(:pos) { game.position }

  #   it "MTD(f)" do
  #     puts "\niterative_deepening_mtdf" 
  #     @s::select_move(pos, @depth) { @s::iterative_deepening_mtdf }[0].to_s.should == "f2f3"
  #   end
  #   it "MTD(f)-Step" do
  #     puts "\niterative_deepening_mtdf_step" 
  #     @s::select_move(pos, @depth) { @s::iterative_deepening_mtdf_step }[0].to_s.should == "f2f3"
  #   end
  #   it "Alpha Beta" do
  #     puts "\niterative_deepening_alpha_beta" 
  #     @s::select_move(pos, @depth) { @s::iterative_deepening_alpha_beta }[0].to_s.should == "f2f3"
  #   end
  # end

  # describe "static exchange evaluation" do
  #   # let(:loc) { Chess::Location::get_location_by_coordinates(5,6) }
  #   let(:see_pos) { Chess::Notation::fen_to_position("5k2/7p/8/5p2/p1p2P2/Pr1RP1K1/1P5P/8 b - - 0 1") }

  #   it "should correctly value an exchange over a single square" do
  #     see_pos.board.print
  #     captures = see_pos.get_captures
  #     captures.each { |m| puts "#{m.to_s} : #{m.see}" }
  #     captures.collect{ |m| m.see }.should == [510, 510, 100, -410]
  #   end
  # end

  describe "playing strength" do
    let(:problems) { load_test_suite('./test_suites/wac_300.epd') }
    
    it "should be able to take standardized tests" do
      take_test(problems, @depth, false)
    end
  end

end















