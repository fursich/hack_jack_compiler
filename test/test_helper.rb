require File.expand_path('../../lib/driver', __FILE__)
require 'minitest/autorun'
require 'pry'
Dir.glob(File.expand_path('test/*/**/*_helper.rb')).each { |f| require f }
