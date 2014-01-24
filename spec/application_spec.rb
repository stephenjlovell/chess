#-----------------------------------------------------------------------------------
# Copyright (c) 2013 Stephen J. Lovell
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#-----------------------------------------------------------------------------------

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
    it { should respond_to :halfmove_clock }
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

