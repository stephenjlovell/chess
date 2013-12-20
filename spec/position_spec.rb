require 'spec_helper'

describe Application::Position::ChessPosition do

  before do
    @position = FactoryGirl.build(:position)
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
      it { should respond_to :moves } 
      it { should respond_to :get_castles }
      it { should respond_to :relocate_piece! }
      it { should respond_to :set_castle_flag! }
      it { should respond_to :promote_pawn! }
    end
  end

  describe "move generation" do
    describe "generates a list of edges" do
      it "to child positions" do
        @position.edges.each do |child| 
          child.class.should == Application::Position::ChessPosition
        end
      end
      it "to child positions involving captures" do
        tactical_edges = @position.tactical_edges
        tactical_edges.should_not be_empty
        tactical_edges.each do |pos|
          pos.class.should == Application::Position::ChessPosition
        end
      end
    end
  end

  describe "when using the copy method" do
    let(:dup) { @position.copy }

    it "should return a new independent object" do
      dup.pieces[:w]["a1"] = :foo
      @position.pieces[:w]["a1"].should_not == :foo
    end
  end

  describe "should know about its parent position" do
    let(:child) { @position.edges.first }
    it { child.parent.should == @position }
  end

end








