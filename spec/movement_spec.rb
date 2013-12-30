require 'spec_helper'

# number of possible games for each ply (http://oeis.org/A048987/list)
MAX_TREE = [1,20,400,8902,197281,4865609,119060324,3195901860,84998978956,2439530234167,69352859712417]

describe Application::Movement do
  
  before do 
    @game = Application::Game.new
    @root = @game.position
  end

  describe "move generation" do

    it "should generate the correct number of nodes" do
      t0 = Time.now
      node_count = Perft(@root, 4) #first castling moves would occur at minimum ply 5.
      t1 = Time.now
      puts "Move generation created #{node_count} nodes in #{t1-t0} seconds."
      node_count.should == MAX_TREE[4]
    end # at depth 4, expecting 197,281 but get 197,742.
  end

end