
puts 'loading chess library'

require './lib/application.rb'

# # #  test initial moves available to pieces:
  # white_pieces = Application::current_position.pieces[:w]
  # white_pieces.each { |p| print p.symbol, ' ', p.position, ' => ', p.get_moves(Application::current_position.board), "\n" }
  # print Application.current_position.get_moves
# test moves available to a pawn:
  # b = Application::current_position.board
  # wp = Application::Pieces::Pawn.new(7,5,:w) # in position to attack
  # moves = wp.get_moves(b)
  # print moves # => [[[7, 5], [8, 6], 1.0], [[7, 5], [8, 4], 1.0]] => true 

  # pos = Application::current_position
  # print pos
  # piece = pos.pieces[:w][1]
  # move = [piece, [4,4], 0.0]
  # 100000.times do  # 4 seconds
  #   new_position = Application::Position::create_position(pos, move)
  # end

  