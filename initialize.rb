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

puts 'loading chess library'

require './lib/application.rb'

# #  test initial moves available to pieces:
  # white_pieces = Application::current_position.pieces[:w]
  # white_pieces.each { |coordinate, piece| print piece.symbol, ' ', piece.position, ' => ', piece.get_moves(Application::current_position), "\n" }
  # print Application::current_position.get_moves

# test attacks available to a pawn:
  # b = Application::current_position.board
  # wp = Application::Pieces::Pawn.new(7,5,:w) # in position to attack
  # moves = wp.get_moves(Application::current_position)
  # print moves

  # pos = Application::current_position
  # print pos
  # piece = pos.pieces[:w][1]
  # move = [piece, [4,4], 0.0]
  # 100000.times do  # 4 seconds
  #   new_position = Application::Position::create_position(pos, move)
  # end

  t0 = Time.now
  print Application::Search::select_move
  t1 = Time.now

  puts "move selected in #{t1 - t0} seconds."

  # 5 ply => 0.93 seconds
  # 6 ply => 1.89 seconds
  # 7 ply => 24.83 seconds

# # test Board.copy
#   b = Application::current_position.board
#   b2 = b.copy
#   b.print
#   b2.print









  