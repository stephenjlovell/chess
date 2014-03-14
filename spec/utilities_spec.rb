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

describe Chess::Notation do

  INITIAL_FEN = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1'
  EPD =  '2rr3k/pp3pp1/1nnqbN1p/3pN3/2pP4/2P3Q1/PPB4P/R4RK1 w - - bm Qg6; id "WAC.001";' # example EPD record

  let(:test_pos) { FactoryGirl.build(:test_position) }

  it 'can accurately translate to and from Forsyth-Edwards Notation' do
    pos = Chess::Notation::fen_to_position(INITIAL_FEN) # FEN to position
    pos.to_s.should == INITIAL_FEN  # and back to FEN.

    midgame_fen = test_pos.to_s  # position to FEN
    new_pos = Chess::Notation::fen_to_position(midgame_fen) # and back to position.
    new_pos.to_s.should == midgame_fen
  end

  it 'can also convert from EPD notation' do  # does not consider halfmove clock.
    pos = Chess::Notation::epd_to_position(EPD) # EPD to position
    pos.class.should == Chess::Position
  end

  describe 'when translating long algebraic chess notation' do
    pending '' do

    end
  end

end













