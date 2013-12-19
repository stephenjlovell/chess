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

  it { should_not respond_to(:squares) } # squares should be private.
  # Currently squares are write-only for testing; if an attribute accessor could 
  # be added to Board Factory as a singleton, could remove attr_writer from class.

  it 'should place pieces in the correct initial position' do
    @board[2,10].should == :XX  # square [2,10] should be out of bounds.
    @board[4,2].should == nil   # square [4,2] should be nil.
    @board[2,6].should == :wK   # white king should be located at [2,6]
    @board[9,5].should == :bQ   # black queen should be located at [9,5]
  end

  describe 'when inspecting a square, can determine' do 
    it 'if a square is empty' do
      @board.empty?(4,2).should be_true
    end
    it 'if out of bounds' do
      @board.out_of_bounds?(2,10).should be_true
    end 
    it 'if occupied' do
      @board.occupied?(2,6).should be_true
    end
    it 'if occupied by an enemy' do
      @board.enemy?(2,6,:w).should be_false
      @board.enemy?(9,5,:w).should be_true
    end
    it 'if a move target is pseudo-legal' do
      @board.pseudo_legal?(2,6,:w).should be_false
      @board.pseudo_legal?(9,5,:W).should be_true
      @board.pseudo_legal?(4,2,:w).should be_true
    end
  end

  it 'should know if the king is in check' do
    
  end

end




