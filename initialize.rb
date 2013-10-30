
puts 'loading chess library'

require './lib/application.rb'

# temporary test of initial moves available to pieces:
g = Application::current_game
pieces = g.current_position.pieces
pieces.each { |p| print p.symbol, ' ', p.position, ' => ', p.get_moves(g.board), "\n" }


