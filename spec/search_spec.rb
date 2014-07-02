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
# require 'profile'

describe Chess::Search do

  before do 
    @s = Chess::Search
    @depth = 6
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

  SEE_TESTS = {
    "5k2/7p/8/5p2/p1p2P2/Pr1RP1K1/1P5P/8 b - - 0 1" => [510, 510, 100, -410],
    "r3k2r/pbp2pp1/3b1n2/1p6/3P3p/1B2N1Pq/PP1PQP1P/R1B2RK1 b kq - 0 1" => [0, -133, -370, -680, -780],
    "2rqkb1r/p1pnpppp/3p3n/3B4/2BPP3/1QP5/PP3PPP/RN2K1NR w KQk - 0 1" => [87],
    "8/8/3p4/4r3/2RKP3/5k2/8/8 b - -" => [100,-99900]
  }

  # describe "static exchange evaluation" do
  #   SEE_TESTS.each do |fen, see_arr|
  #     it "should correctly value exchanges over a single square" do
  #       see_pos = Chess::Notation::fen_to_position(fen)
  #       see_pos.board.print
  #       captures = see_pos.get_all_captures
  #       captures.each { |m| puts "#{m.to_s} : #{m.see}" }
  #       captures.collect{ |m| m.see }.should == see_arr
  #     end
  #   end
  # end

  describe "playing strength" do
    let(:problems) { load_test_suite('./test_suites/wac_300.epd') }
    
    it "should be able to take standardized tests" do
      take_test(problems, @depth, false)
    end
  end

end















