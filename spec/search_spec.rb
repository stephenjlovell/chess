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

describe Chess::Search do

  before { @s = Chess::Search }
  let(:game) { FactoryGirl.build(:test_game) }
  let(:pos) { game.position }

  # describe "when AI king is not in check" do
  #   it "will select the most valuable move" do
  #     Chess::Search::select_move(@pos)
  #   end
  # end

  # describe "when AI king is in check" do    # king captures cannot be permitted
  #   it "will move out of check if possible" do
  #     Chess::Search::select_move(@check_pos)
  #   end
  # end

  describe "permits use of" do
    describe "mtdf" do
      # it "as a standalone algorithm" do
      #   puts "--mtdf-- \n #{@s::select_move(pos, 4){ @s::mtdf } }"
      #   puts "max |m #{$main_calls} |q #{$quiescence_calls} |t #{$main_calls+$quiescence_calls} |e #{$evaluation_calls} |m #{$memory_calls} |n #{$non_replacements}"
      # end
      # it "from within an iterative deepening framework" do
      #   puts "--iterative_deepening_mtdf-- \n #{@s::select_move(pos, 4) { @s::iterative_deepening_mtdf } }"
      # end
    end
    describe "alpha beta" do
      # it "as a standalone algorithm" do
      #   puts "--alpha_beta-- \n #{@s::select_move(pos, 4) { @s::alpha_beta } }"
      #   puts "max |m #{$main_calls} |q #{$quiescence_calls} |t #{$main_calls+$quiescence_calls} |e #{$evaluation_calls} |m #{$memory_calls} |n #{$non_replacements}"
      # end
      it "from within an iterative deepening framework" do
        puts "--iterative_deepening_alpha_beta-- \n #{@s::select_move(pos, 5) { @s::iterative_deepening_alpha_beta } }"
      end
    end
  end

  # describe "static exchange evaluation" do
  #   let(:loc) { Chess::Location::get_location(5,6) }
  #   let(:see_pos) { FactoryGirl.build(:see_position) }
  #   it "should correctly value an exchange over a single square" do
  #     see_pos.board.print
  #     @s.get_see_score(see_pos, loc)
  #   end
  # end


end















