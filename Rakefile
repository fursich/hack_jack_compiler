require "rake/testtask"
require 'pry'
require_relative 'lib/driver'

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

task :default => :test

task :parse, [:filename] do |_task, args|
  raw_source = JackCompiler::FileIO.new(args.filename).read
  source     = JackCompiler::Source.new(args.filename).tap { |source| source.store!(raw_source) }
  tokenizer  = JackCompiler::Tokenizer::Processor.new(source).tap(&:tokenize!)
  parser     = JackCompiler::Parser::Processor.new(tokenizer.tokens).tap(&:parse!)
  parser.print
end

# TO BE IMPLEMENTED
# task :run, [:filename] do |_task, args|
#   VMTranslator::Driver.new(args.filename).run
# end
