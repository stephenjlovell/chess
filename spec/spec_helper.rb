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

require 'factory_girl'

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
end

load './lib/application.rb'
require 'factories.rb'

def Perft(node, depth)  # Performance tester. Counts all leaf nodes to specified depth.
  return 1 if depth == 0
  sum = 0
  moves = node.get_moves
  moves.each do |move|
    Application::MoveGen::make_unmake!(node, move) { sum += Perft(node, depth-1) }
  end
  return sum
end











