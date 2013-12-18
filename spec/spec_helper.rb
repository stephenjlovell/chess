
require 'factory_girl'

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
end

require './lib/application.rb'
require 'factories.rb'
