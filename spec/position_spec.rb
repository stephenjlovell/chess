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

describe Application::Position::ChessPosition do

  before { @position = FactoryGirl.build(:test_position) }
  subject { @position }

  describe "should respond to public methods" do
    it { should respond_to :board }
    it { should respond_to :pieces }
    it { should respond_to :side_to_move }
    it { should respond_to :enemy }
    it { should respond_to :halfmove_clock }
    it { should respond_to :castle }
    it { should respond_to :enp_target }
    it { should respond_to :hash }
    it { should respond_to :get_moves } 
  end

  describe "move generation" do
    describe "generates a list of edges" do
      it "containing valid moves" do
        @position.edges.each do |m| 
          m.should respond_to :make!
          m.should respond_to :unmake!
        end
      end
      it "to tactical edges involving captures" do
        tactical_edges = @position.tactical_edges
        tactical_edges.count.should == 2
        tactical_edges.each do |m|
          m.should respond_to :make!
          m.should respond_to :unmake!
        end
      end
    end
  end

end








