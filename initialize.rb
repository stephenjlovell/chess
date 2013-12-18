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

require './lib/application.rb'
puts "Chess library loaded. \n\n"

# # Play the game!
# Application::CLI::play

# #  test initial moves available to pieces:
  # white_pieces = Application::current_position.pieces[:w]
  # white_pieces.each { |coordinate, piece| print piece.symbol, ' ', piece.position, ' => ', piece.get_moves(Application::current_position), "\n" }
  # print Application::current_position.get_moves

# # test attacks available to a pawn:
  # b = Application::current_position.board
  # wp = Application::Pieces::Pawn.new(7,5,:w) # in position to attack
  # moves = wp.get_moves(Application::current_position)
  # print moves

  def test_move_generation
    g = Application::new_game
    pos = Application::current_position  
    t0 = Time.now
    best_pos = Application::Search::select_position
    t1 = Time.now

    puts best_pos.previous_move.to_s
    puts "value: #{best_pos.value}"
    puts "move selected in #{t1 - t0} seconds."
    puts "#{$main_calls} + #{$quiescence_calls} total nodes explored."
    # best_pos.board.print
  end
  test_move_generation


# test Transposition Table hash function efficiency.
  # g = Application::new_game(:w)
  # h = 0
  # t0 = Time.now
  # 1000.times do 
  #   h = g.tt.hash(g.position.board)
  # end # 0.053708 seconds
  # t1 = Time.now
  # puts "The hash value for initial position is: #{h}"
  # puts t1-t0







  