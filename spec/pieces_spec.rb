describe Application::Pieces do


  describe " chess pieces" do
    before do 
      @piece  = Application::Pieces::Knight.new(5,5,:b)
      @board = Application::Board.new
    end
    subject { @piece }
    it { should respond_to :symbol }
    it { should respond_to :get_moves }
    it { should_not respond_to :explore_direction }
    
    it "should generate a list of valid moves" do 
      @piece.get_moves(@board).should == [[7, 6, 0.0], [6, 7, 0.0], [3, 6, 1.0], [4, 7, 0.0], 
                                          [3, 4, 1.0], [4, 3, 0.0], [7, 4, 0.0], [6, 3, 0.0]] 
    end



  end





end