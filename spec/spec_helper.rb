
require 'factory_girl'

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
end

load './lib/application.rb'
require 'factories.rb'

def Perft(node, depth)  # Counts all leaf nodes to specified depth.
  return 1 if depth == 0
  node.get_children.inject(0) { |sum, c| sum + Perft(c, depth-1) }
end
