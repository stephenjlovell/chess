describe Application::Pieces do


  describe "chess pieces" do
    before do 
      @knight  = Application::Pieces::Knight.new(5,5,:b)
      @board = Application::Board.allocate
      @board.setup
    end
    subject { @knight }

    describe "should respond to public methods only" do
      it { should respond_to :symbol }
      it { should respond_to :get_moves }
      it { should_not respond_to :explore_direction }
    end
    
    it "should generate a list of valid moves" do 
      @knight.get_moves(@board).should == [[@knight, [7, 6], 0.0], [@knight, [6, 7], 0.0], 
                                           [@knight, [3, 6], 1.0], [@knight, [4, 7], 0.0], 
                                           [@knight, [3, 4], 1.0], [@knight, [4, 3], 0.0], 
                                           [@knight, [7, 4], 0.0], [@knight, [6, 3], 0.0]] 
    end

    describe "pawns" do
      before do
        @pawn = Application::Pieces::Pawn.new(7,5,:w)

      end


    end
  end


end