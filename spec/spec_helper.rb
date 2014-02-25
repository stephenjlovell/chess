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
    Chess::MoveGen::make!(node, move) 
    sum += perft(node, depth-1)
    Chess::MoveGen::unmake!(node, move)
  end
  return sum
end

Problem = Struct.new(:id, :position, :best_moves, :avoid_moves, :ai_response, :score)

def load_test_suite(file)
  raise "test suite #{file} not found" unless File.exists?(file)
  problems = []
  File.readlines(file).each do |line|
    line = %Q{#{line}}
    pos = Chess::Notation::epd_to_position(line)
    best_moves = best_moves_from_epd(line)
    avoid_moves = avoid_moves_from_epd(line)
    id = id_from_epd(line)
    problems << Problem.new(id, pos, best_moves, avoid_moves)
  end
  return problems
end

def id_from_epd(epd)
  return epd[epd.index('id')+4..epd.index(';',epd.index('id')+4)-2]
end

def best_moves_from_epd(epd)
  return [] if epd.index('bm').nil?
  epd[epd.index('bm')+3..epd.index(';')-1].split(' ') # scan string for "bm <move>;"
end

def avoid_moves_from_epd(epd)
  return [] if epd.index('am').nil?
  epd[epd.index('am')+3..epd.index(';')-1].split(' ') # scan string for "am <move>;"
end

def take_test(problems, depth=nil)
  correct, total = 0, 0
  problems.each do |prob|
    move = Chess::Search::select_move(prob.position, depth)
    prob.ai_response = move
    prob.score = score_question(prob)
    puts prob.id
    correct += prob.score
    total += 1
    puts "Best: #{prob.best_moves} Avoid: #{prob.avoid_moves} AI Answer: #{prob.ai_response.print}"
    puts "Running score: #{correct}/#{total} (#{(correct+0.0)/total*100}%)"   
  end
  puts "\n"
  tp problems, :id, :best_moves, :avoid_moves, :ai_response, :score
  total_right, count = score_test(problems), problems.count
  puts "Total AI score: #{total_right}/#{count} (#{((total_right+0.0)/count)*100}%)"
end

def score_test(problems)
  problems.inject(0) { |memo, prob| memo += score_question(prob) }
end

def score_question(problem) # answer is considered correct if it matches any answer 
  # in the best_moves field, and does not match any answer in the avoid_moves field.
  problem.best_moves.each do |pgn| 
    return 1 if move_matches_pgn?(problem.ai_response, pgn)
  end
  problem.avoid_moves.each do |pgn|
    return 0 if move_matches_pgn?(problem.ai_response, pgn)
  end
  return problem.best_moves.empty? ? 1 : 0
end

def move_matches_pgn?(move, pgn)
  type, to = move.piece.class.type.to_s, move.to.to_s
  if pgn.length == 2
    return pgn == to 
  elsif pgn[-1] == "+"
    new_pgn = pgn.slice(0..-2)
    return new_pgn[0] == type && new_pgn[-2..-1] == to  # this should also test whether the correct piece is moving.
  else
    return pgn[0] == type && pgn[-2..-1] == to
  end
end








