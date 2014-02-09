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

require './initialize.rb'

require 'factory_girl'

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
end

require 'factories.rb'

def perft(node, depth)  # Performance tester. Counts all leaf nodes to specified depth.
  return 1 if depth == 0
  sum = 0
  moves = node.get_moves
  moves.each do |move|
    Chess::MoveGen::make_unmake!(node, move) { sum += perft(node, depth-1) }
  end
  return sum
end

Problem = Struct.new(:position, :best_moves, :avoid_moves, :ai_response)

def load_test_suite(file)
  raise "file #{file} not found" unless File.exists?(file)
  problems = []
  File.readlines(file).each do |line|
    pos = Chess::Notation::epd_to_position(line)
    best_moves = best_moves_from_epd(line)
    avoid_moves = avoid_moves_from_epd(line)
    problems << Problem.new(pos, best_moves)
  end
  return problems
end

def best_moves_from_epd(epd)
  return nil if epd.index('bm').nil?
  moves = epd[epd.index('bm')+3..epd.index(';')-1].split(' ') # scan string for "bm <move>;"
end

def avoid_moves_from_epd(epd)
  return nil if epd.index('am').nil?
  moves = epd[epd.index('am')+3..epd.index(';')-1].split(' ') # scan string for "am <move>;"
end








