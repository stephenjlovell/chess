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

describe Application::Board do

  before { @board = FactoryGirl.build(:board) }
  subject { @board }

  it { should respond_to(:each) }
  it { should respond_to(:[]) }
  it { should respond_to(:empty?) }
  it { should respond_to(:out_of_bounds?) }
  it { should respond_to(:enemy?) }
  it { should respond_to(:squares) }

  it 'should place pieces in the correct initial position' do
    @board.square(2,10).should == :XX  # square [2,10] should be out of bounds.
    @board.square(4,2).should == nil   # square [4,2] should be nil.
    @board.square(2,6).should == :wK   # white king should be located at [2,6]
    @board.square(9,5).should == :bQ   # black queen should be located at [9,5]
  end

  describe 'when inspecting a square, it can determine' do
    before do
      @empty = FactoryGirl.build(:location, r: 4, c: 2)
      @out = FactoryGirl.build(:location, r: 2, c: 10)
      @occupied = FactoryGirl.build(:location, r: 2, c: 6)
      @enemy = FactoryGirl.build(:location, r: 9, c: 5)
    end

    it 'if a square is empty' do
      @board.empty?(@empty).should be_true
    end
    it 'if out of bounds' do
      @board.out_of_bounds?(@out).should be_true
    end 
    it 'if occupied' do
      @board.occupied?(@occupied).should be_true
    end
    it 'if occupied by an enemy' do
      @board.enemy?(@occupied,:w).should be_false
      @board.enemy?(@enemy,:w).should be_true
    end
    it 'if a move target is pseudo-legal' do
      @board.pseudo_legal?(@out,:w).should be_false
      @board.pseudo_legal?(@enemy,:W).should be_true
      @board.pseudo_legal?(@empty,:w).should be_true
    end
  end

  describe 'king saftey' do
    before do
      @position = FactoryGirl.build(:test_position)
      @board = FactoryGirl.build(:test_board)
      @threat_board = FactoryGirl.build(:test_board)
      @threat_board.squares[3][7] = :bP
      @from = FactoryGirl.build(:location, r: 2, c: 6)
      @to = FactoryGirl.build(:location, r: 3, c: 7)
      @alt_from = FactoryGirl.build(:location, r: 2, c: 3)
      @alt_to = FactoryGirl.build(:location, r: 2, c: 4)
    end

    it 'should know if the specified king is in check' do
      @board.print
      @threat_board.print
      @board.king_in_check?(@position, :w).should be_false
      @board.king_in_check?(@position, :b).should be_false
      @threat_board.king_in_check?(@position, :w).should be_true
      @threat_board.king_in_check?(@position, :b).should be_false
    end

    it 'should test if a move would get specified side out of check' do
      @threat_board.avoids_check?(@position, @from, @to, :w).should be_true
      @threat_board.avoids_check?(@position, @alt_from, @alt_to, :w).should be_false
    end

  end

end




