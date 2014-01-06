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

  before do
    # @position = FactoryGirl.build(:position)
    @position = Application::current_position
    @pieces = @position.pieces
    @board = @position.board
  end

  subject { @position }

  describe "should respond to public methods" do
    it { should respond_to :board }
    it { should respond_to :pieces }
    it { should respond_to :side_to_move }
    it { should respond_to :previous_move }
    it { should respond_to :options }
    describe "and public mixed-in methods" do
      it { should respond_to :get_moves } 
      it { should respond_to :get_castles }
      it { should respond_to :relocate_piece! }
      it { should respond_to :set_castle_flag! }
      it { should respond_to :promote_pawn! }
    end
  end

  describe "move generation" do
    describe "generates a list of edges" do
      it "containing valid moves" do
        @position.edges.each do |m| 
          m.should respond_to :move!
          m.should respond_to :create_position
        end
      end
      it "to child positions involving captures" do
        # tactical_edges = @position.tactical_edges
        # tactical_edges.should_not be_empty
        # tactical_edges.each do |pos|
        #   pos.class.should == Application::Position::ChessPosition
        # end
      end
    end
  end

  describe "when using the copy method" do
    let(:dup) { @position.copy }

    it "should return a new independent object" do
      dup.pieces[:w]["a1"] = :foo
      @pieces[:w]["a1"].should_not == :foo
    end
  end

  describe "should know about its parent position" do
    let(:child) { @position.edges.first.create_position }
    it { child.parent.should == @position }
  end

end








