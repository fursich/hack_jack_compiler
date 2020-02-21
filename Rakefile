require "rake/testtask"
require 'pry'
# require_relative 'lib/driver'

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

task :default => :test

# TO BE IMPLEMENTED
# task :run, [:filename] do |_task, args|
#   VMTranslator::Driver.new(args.filename).run
# end
