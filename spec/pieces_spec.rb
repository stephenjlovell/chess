describe Application::Pieces do
  describe "chess pieces" do
    before do
      @game = Application::Game.new
      @position = @game.position
      @board = @position.board 
      @knight  = Application::Pieces::Knight.new(5,5,:b) # D4
    end

    subject { @knight }

    describe "should respond to public methods only" do
      it { should respond_to :copy }
      it { should respond_to :symbol }
      it { should respond_to :square }
      it { should respond_to :color }
      it { should respond_to :position }
      it { should respond_to :get_moves }
      it { should_not respond_to :explore_direction }
    end

    describe "knights" do
      let(:moves){ @knight.get_moves(@position) }

      it "should generate a list of valid moves" do  # position, square, target, capture_value, options
        moves.collect do |move| 
          move.target
        end.should == [[7, 6], [6, 7], [3, 6], [4, 7], [3, 4], [4, 3], [7, 4], [6, 3]]
      end

    end

    describe "pawns" do
      before do 
        @pawn = Application::Pieces::Pawn.new(7,5,:w) # D5
      end
      
      subject { @pawn }
      let(:moves) { @pawn.get_moves(@position) }

      it "should attack diagnally" do
        moves.collect { |m| m.target }.should == [[8,6],[8,4]]
      end

    end
  end

  # describe Application::Pieces helper methods

end





