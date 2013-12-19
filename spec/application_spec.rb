require 'spec_helper'

describe Application do  
  before { @app = Application }
  subject { @app }

  it { should respond_to :current_game }    
  it { should respond_to :new_game }
  it { should respond_to :current_position }
  it { should respond_to :current_side }
  it { should respond_to :current_board }
  it { should respond_to :print }

  describe Application::Game do
    before { @game = Application::Game.new(:b) }
    subject { @game }
    it { should respond_to :position }    
    it { should respond_to :halfmove_counter }
    it { should respond_to :tt }
    it { should respond_to :clock }
    it { should respond_to :ai_player }
    it { should respond_to :opponent }

    describe "should assign teams correctly" do
      its(:ai_player) { should == :b }
      its(:opponent) { should == :w }
    end

    describe "should contain objects of the right class" do
      its("clock.class") { should == Application::Clock }
      its("tt.class") { should == Application::Memory::TranspositionTable }
      its("position.class") { should == Application::Position::ChessPosition }
    end
  end

  describe Application::Clock do
    before { @clock = Application::Clock.new }
    subject { @clock }
    it { should respond_to :game_start }
    it { should respond_to :time_up? }
    it { should respond_to :restart }
    it { should respond_to :end_turn }
  end
  
end

