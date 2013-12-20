require 'spec_helper'

describe Application::Pieces do
  describe "chess pieces" do
    before do
      @game = Application::Game.new
      @position = @game.position
      @board = @position.board 
      @knight  = Application::Pieces::Knight.new(:b) # D4
    end

    subject { @knight }

    describe "should respond to public methods only" do
      it { should respond_to :copy }
      it { should respond_to :symbol }
      it { should respond_to :color }
      it { should respond_to :get_moves }
      it { should_not respond_to :explore_direction }
      its(:class) { should respond_to :value }
      its(:class) { should respond_to :type }
      its(:class) { should respond_to :move_until_blocked? }
    end

    describe "knights" do
      before { @from = FactoryGirl.build(:location, r: 5, c: 5) }
      let(:moves){ @knight.get_moves(@from, @position) }

      it "should generate a list of valid moves" do  # position, square, target, capture_value, options
        targets = moves.collect { |m| m.to.to_a }
        targets.should == [[7, 6], [6, 7], [3, 6], [4, 7], [3, 4], [4, 3], [7, 4], [6, 3]]
      end

    end

    describe "pawns" do
      before do
        @from = FactoryGirl.build(:location, r: 7, c: 5) 
        @pawn = Application::Pieces::Pawn.new(:w) # D5
      end
      
      subject { @pawn }
      let(:moves) { @pawn.get_moves(@from, @position) }

      it "should attack diagnally" do
        moves.collect { |m| m.to.to_a }.should == [[8,6],[8,4]]
      end

    end
  end

  # describe Application::Pieces helper methods

end





