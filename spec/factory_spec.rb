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

require 'spec_helper'

FactoryGirl.factories.map(&:name).each do |factory_name|
  describe "factory #{factory_name}" do
    it 'is valid' do
      factory = build(factory_name)

      if factory.respond_to?(:valid?)
        expect(factory).to be_valid, lambda { factory.errors.full_messages.join(',') } # the lamba syntax only works with rspec 2.14 or newer;  for earlier versions, you have to call #valid? before calling the matcher, otherwise the errors will be empty
      end
    end
  end

  describe 'with trait' do
    FactoryGirl.factories[factory_name].definition.defined_traits.map(&:name).each do |trait_name|
      it "is valid with trait #{trait_name}" do
        factory = build(factory_name, trait_name)
          
        if factory.respond_to?(:valid?)
          expect(factory).to be_valid, lambda { factory.errors.full_messages.join(',') } # see above
        end
      end
    end
  end
end