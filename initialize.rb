
puts 'loading chess library'

require './lib/application.rb'

# #  test initial moves available to pieces:
  pieces = Application::current_position.pieces
  pieces.each { |p| print p.symbol, ' ', p.position, ' => ', p.get_moves(Application::current_position.board), "\n" }
  # print Application.current_position.get_moves
# test moves available to a pawn:
  # b = Application::current_position.board
  # wp = Application::Pieces::Pawn.new(7,5,:w) # in position to attack
  # moves = wp.get_moves(b)
  # print moves # => [[[7, 5], [8, 6], 1.0], [[7, 5], [8, 4], 1.0]] => true 
  