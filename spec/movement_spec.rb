require 'spec_helper'

# number of possible games for each ply (http://oeis.org/A048987/list)
MAX_TREE = [1,20,400,8902,197281,4865609,119060324,
            3195901860,84998978956,2439530234167,
            69352859712417,2097651003696806,62854969236701747,
            1981066775000396239]

describe Application::Movement do
  
  before do 
    @game = Application::Game.new
    @root = @game.position
  end

  describe "move generation" do
    it "should generate the correct number of nodes" do
      (0..3).each { |n| Perft(@root, n).should == MAX_TREE[n] }
    end # at depth 4, expecting 197,281 but get 197,742
  end


  # time to add some tests here.

end