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

  describe "Chess pieces" do
    before do
      @game = Chess::Game.new
      @position = @game.position
      @board = @position.board 
      @knight  = Chess::Pieces::Knight.new(:b) # D4
    end

    subject { @knight }

    describe "should respond to public methods only" do
      its(:class) { should respond_to :value }
      its(:class) { should respond_to :type }
      its(:class) { should respond_to :id }
      it { should respond_to :symbol }
      it { should respond_to :color }
      it { should respond_to :get_moves }
      it { should_not respond_to :explore_direction }
    end

    describe "knights" do
      before { @from = FactoryGirl.build(:location, r: 5, c: 5) }
      let(:moves) do
        moves = []
        @knight.get_moves(@position, @from, moves, [], [], [])
        return moves
      end

      it "should generate a list of valid moves" do  # position, square, target, capture_value, options
        targets = moves.collect { |m| m.to.to_a }
        targets.should == [[7, 4], [7, 6], [6, 7], [4, 7], [4, 3], [6, 3]]
      end

    end

end





