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

describe Chess::Board do

  before { @board = FactoryGirl.build(:board) }
  subject { @board }

  it { should respond_to(:each) }
  it { should respond_to(:[]) }
  it { should respond_to(:empty?) }
  it { should respond_to(:on_board?) }
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
      @board.on_board?(@out).should be_false
    end 
    it 'if occupied' do
      @board.occupied?(@occupied).should be_true
    end
    it 'if occupied by an enemy' do
      @board.enemy?(@occupied,:w).should be_false
      @board.enemy?(@enemy,:w).should be_true
    end
  end

  describe 'king saftey' do
    before do
      @position = FactoryGirl.build(:check_position)
      @board = @position.board
      @from = FactoryGirl.build(:location, r: 3, c: 8) # G2
      @to = FactoryGirl.build(:location, r: 4, c: 8) # G3
      @alt_from = FactoryGirl.build(:location, r: 3, c: 3) # B2
      @alt_to = FactoryGirl.build(:location, r: 4, c: 3) # B3
    end

    it 'should know if the specified king is in check' do
      @board.king_in_check?(@position, :w).should be_true
      @board.king_in_check?(@position, :b).should be_true
    end

    it 'should test if a move would get specified side out of check' do
      @board.evades_check?(@position, @from, @to, :w).should be_true
      @board.evades_check?(@position, @alt_from, @alt_to, :w).should be_false
    end

  end

  describe 'when finding pieces that attack a given square' do
    before do
      @board = FactoryGirl.build(:test_board)
      @location = Chess::Location::get_location(5,8)
      @attackers = @board.get_square_attackers(@location)
    end

    it 'should generate a list of squares holding pieces that attack the given square' do
      @attackers[:w].should == [Chess::Location::get_location(2,5)]
      @attackers[:b].should == [Chess::Location::get_location(7,7)]
    end

  end



end









