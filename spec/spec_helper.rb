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
RSpec.configure { |config| config.include FactoryGirl::Syntax::Methods }
require 'factories.rb'

$print_count = 0

def perft(node, depth)  # Legal MoveGen speed/accuracy test. Counts all leaf nodes at depth.
  return 1 if depth == 0
  sum = 0
  node.get_moves(depth, true).each do |move|
    Chess::MoveGen::make!(node, move)
    sum += perft(node, depth-1)
    Chess::MoveGen::unmake!(node, move)
  end
  return sum
end

def perft_legal(node, depth)  # Pseudolegal MoveGen speed test. Counts all leaf nodes at depth.
  return 1 if depth == 0
  sum = 0
  node.get_moves(depth, true).each do |move|
    next unless node.evades_check?(move)
    Chess::MoveGen::make!(node, move) 
    sum += perft_legal(node, depth-1)
    Chess::MoveGen::unmake!(node, move)
  end
  return sum
end

def test_notation_conversion(file)
  raise "test suite #{file} not found" unless File.exists?(file)
  raise "block required" unless block_given?
  count = 0
  File.readlines(file).each do |line|
    count += 1
    line = %Q{#{line}}

    original_fen = Chess::Notation::epd_to_fen(line)
    pos = Chess::Notation::fen_to_position(original_fen)
    new_fen = Chess::Notation::position_to_fen(pos)
    yield(original_fen, new_fen)
  end
end

def generate_moves_for_each(file, depth)
  raise "test suite #{file} not found" unless File.exists?(file)
  File.readlines(file).each_with_index do |line, i|
    line = %Q{#{line}}
    pos = Chess::Notation::epd_to_position(line)
    perft(pos, depth)
    print "#{i+1}."
  end
end

ChessProblem = Struct.new(:id, :position, :best_moves, :avoid_moves, :ai_response, :score)

def load_test_suite(file)
  raise "test suite #{file} not found" unless File.exists?(file)
  problems = []
  File.readlines(file).each do |line|
    line = %Q{#{line}}

    pos = Chess::Notation::epd_to_position(line)
    best_moves = best_moves_from_epd(line)
    avoid_moves = avoid_moves_from_epd(line)
    id = id_from_epd(line)
    problems << ChessProblem.new(id, pos, best_moves, avoid_moves)
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

def take_test(problems, depth, verbose=false)
  aggregator = Chess::Analytics::Aggregator.new(depth)
  
  t0 = Time.now
  puts t0
  answer_questions(problems, depth, aggregator, verbose)
  time = Time.now - t0

  if verbose
    puts "\n"
    tp problems, :id, :best_moves, :avoid_moves, :ai_response, :score
  end
  total_right = problems.inject(0) { |memo, prob| memo += score_question(prob) }
  count =  problems.count
  accuracy = ((total_right+0.0)/count)*100
  aggregator.print
  puts "\nTotal AI score: #{total_right}/#{count} (#{accuracy}%)"
  puts "#{time/count} seconds/search at depth #{depth}"
  puts aggregator.print_summary(accuracy)
end

def answer_questions(problems, depth, aggregator, verbose=false)
  correct, total = 0, 0
  problems.each_with_index do |prob, i|
    move, value = Chess::Search::select_move(prob.position, depth, aggregator, verbose)
    prob.ai_response = move
    prob.score = score_question(prob)
    correct += prob.score
    total += 1
    if verbose
      puts prob.id
      puts "Best: #{prob.best_moves} Avoid: #{prob.avoid_moves} AI Answer: #{prob.ai_response}"
      puts "Running score: #{correct}/#{total} (#{(correct+0.0)/total*100}%)"
    else
      # print " | #{i+1}.#{prob.score > 0 ? "-" : "X" }"
      number = prob.score > 0 ? Chess::colorize(i+1,32) : Chess::colorize(i+1,31)
      print "| #{number.rjust(3," ")} "
    end
  end
end 

def score_question(problem) # answer is considered correct if it matches any answer in
                            # best_moves, and does not match any answer in avoid_moves.
  problem.best_moves.each { |pgn| return 1 if move_matches_pgn?(problem.ai_response, pgn) }
  problem.avoid_moves.each { |pgn| return 0 if move_matches_pgn?(problem.ai_response, pgn) }
  return problem.best_moves.empty? ? 1 : 0
end

def move_matches_pgn?(move, pgn)
  
  return false if move.nil?
  
  type, to = Chess::Pieces::PIECE_TYPES[(move.piece>>1)&7].to_s , Chess::Location::get_location(move.to).to_s
  
  if pgn.length == 2
    return pgn == to
  elsif pgn[-1] == "+"
    new_pgn = pgn.slice(0..-2)
    return new_pgn[0] == type && new_pgn[-2..-1] == to  # this should also test whether the correct piece is moving.
  else
    return pgn[0] == type && pgn[-2..-1] == to
  end


end








