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

describe "Search" do

  before { @s = Application::Search }

  # describe "when AI king is not in check" do
  #   it "will select the most valuable move" do
  #     Application::Search::select_position(@pos)
  #   end
  # end

  # describe "when AI king is in check" do    # king captures cannot be permitted
  #   it "will move out of check if possible" do
  #     Application::Search::select_position(@check_pos)
  #   end
  # end

  describe "strategy pattern permits use of" do
    let(:game) { FactoryGirl.build(:test_game) }
    let(:pos) { game.position }
    describe "mtdf" do
      # it "as a standalone algorithm" do
      #   puts "--mtdf--#{@s::select_position(pos, :mtdf)}"
      # end
      # it "from within an iterative deepening framework" do
      #   puts "--iterative_deepening_mtdf-- #{@s::select_position(pos, :iterative_deepening_mtdf, 4)}"
      # end
    end
    describe "alpha beta" do
      # it "as a standalone algorithm" do
      #   puts "--alpha_beta--#{@s::select_position(pos, :alpha_beta, 5)}"
      #   puts "max |m #{$main_calls} |q #{$quiescence_calls} |t #{$main_calls+$quiescence_calls} |e #{$evaluation_calls} |m #{$memory_calls} |n #{$non_replacements}"
      # end
      it "from within an iterative deepening framework" do
        puts "--iterative_deepening_alpha_beta--#{@s::select_position(pos, :iterative_deepening_alpha_beta, 6)}"
      end
    end
  end

end















