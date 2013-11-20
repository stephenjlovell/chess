require './lib/application.rb'

describe Application::Position do
  describe Application::Position::ChessPosition do

    before do
      @position = Application::current_position # initial chess position at begining of game
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
        it { should respond_to :create_position }
        it { should respond_to :castle! }
        it { should respond_to :move! }
        it { should respond_to :relocate_piece! }
        it { should respond_to :set_en_passant_flag!}
        it { should respond_to :set_castle_flag! }
        it { should respond_to :promote_pawns! }
        it { should respond_to :promote_pawn! }
      end
    end

    it "can generate a list of edges to child positions" do
      @position.edges.each do |pos| 
        pos.class.should == Application::Position::ChessPosition
      end
    end

    describe "when using the copy method" do
      let(:dup) { @position.copy }

      it "should return a new independent object" do
        dup.pieces[:w]["a1"] = :foo
        @position.pieces[:w]["a1"].should_not == :foo
      end

    end

  end
end







