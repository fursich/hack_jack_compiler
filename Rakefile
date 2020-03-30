require "rake/testtask"
require 'pry'
require_relative 'lib/driver'

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

task :default => :test

task :run, [:filename] do |_task, args|
  JackCompiler::Driver.new(args.filename, output: :vm).run
end

task :parse, [:filename] do |_task, args|
  JackCompiler::Driver.new(args.filename, output: :xml).run
end
