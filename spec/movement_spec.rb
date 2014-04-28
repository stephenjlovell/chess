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

# number of possible game states for each ply of depth. (http://oeis.org/A048987/list)
MAX_TREE = [1,20,400,8902,197281,4865609,119060324,3195901860,84998978956,2439530234167,69352859712417]

describe Chess::MoveGen do
  
  before do 
    # @game = FactoryGirl.build(:game)
    @game = Chess::Game.new
    @root = @game.position
    @depth = 4
  end

  describe "move generation" do

    # it "should generate the correct number of legal positions" do
    #   t0 = Time.now
    #   node_count = perft_legal(@root, @depth) # first castling moves would occur at minimum ply 7.
    #   t1 = Time.now
    #   puts "Legal MoveGen: #{node_count/(t1-t0)} NPS"
    #   puts "Node count: #{node_count}"
    #   node_count.should == MAX_TREE[@depth]
    # end

    # it "can generate pseudo-legal positions at lower computational cost" do
    #   t0 = Time.now
    #   node_count = perft(@root, @depth) # first castling moves would occur at minimum ply 7.
    #   t1 = Time.now
    #   puts "Pseudo-legal MoveGen: #{node_count/(t1-t0)} NPS"
    #   puts "Node count: #{node_count}"
    # end

    it "can generate moves for midgame positions" do
      generate_moves_for_each('./test_suites/wac_300.epd', 3)
    end

  end

end







