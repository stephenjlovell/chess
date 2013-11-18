require './lib/application.rb'

describe Application::Position::ChessPosition do

  before do
    @position = Application::current_position # initial chess position at begining of game
    @pieces = @position.pieces
    @board = @position.board
  end

  subject { @position }

  it "should generate a list of edges to child positions" do
    @position.edges.each do |pos| 
      pos.class should == Application::Position::ChessPosition
    end
  end



end