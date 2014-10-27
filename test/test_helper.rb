#test/test_helper.rb
require './lib/boffinio'
require 'minitest/autorun'
require 'webmock/minitest'
require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = "test/fixtures"
  c.hook_into :webmock
end

BoffinIO.api_base="http://api.boffin-dev.io:3000"
BoffinIO.api_key=("141d246d5e0774eaab3482259516dae9")
