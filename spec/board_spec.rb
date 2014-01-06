require 'spec_helper'

describe Application::Board do

  before do 
    @board = Application::Board.allocate
    @board.setup
  end
  
  subject { @board }

  it { should respond_to(:each) }
  it { should respond_to(:[]) }
  it { should respond_to(:empty?) }
  it { should respond_to(:out_of_bounds?) }
  it { should respond_to(:enemy?) }
  it { should respond_to(:squares) }

  it 'should place pieces in the correct initial position' do
    @board.coordinates(2,10).should == :XX  # square [2,10] should be out of bounds.
    @board.coordinates(4,2).should == nil   # square [4,2] should be nil.
    @board.coordinates(2,6).should == :wK   # white king should be located at [2,6]
    @board.coordinates(9,5).should == :bQ   # black queen should be located at [9,5]
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
      @board = Application::Board.allocate
      @board.setup
      @threat_board = @board.copy
      @threat_board.squares[3][7] = :bQ
    end

    it 'should know if the specified king is in check' do
      @board.king_in_check?(:w).should be_false
      @board.king_in_check?(:b).should be_false
      @threat_board.king_in_check?(:w).should be_true
      @threat_board.king_in_check?(:b).should be_false
    end

  end

end




