
puts 'loading chess library'

require './lib/application.rb'

# #  test initial moves available to pieces:
#   g = Application::current_game
#   pieces = g.position.pieces
#   pieces.each { |p| print p.symbol, ' ', p.position, ' => ', p.get_moves(g.board), "\n" }

# test moves available to a pawn:
  # b = Application::current_position.board
  # wp = Application::Pieces::Pawn.new(7,5,:w) # in position to attack
  # moves = wp.get_moves(b)
  # print moves # => [[[7, 5], [8, 6], 1.0], [[7, 5], [8, 4], 1.0]] => true 
  