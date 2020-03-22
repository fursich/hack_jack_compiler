require_relative 'node_factory'
require_relative 'nodes/nodes'
require_relative 'visitor/visitor'

module JackCompiler
  module Transformer
    class Processor
      attr_reader :parse_tree, :factory, :ast

      def initialize(parse_tree)
        @parse_tree = parse_tree
        @factory = NodeFactory
      end

      def transform!
        @ast = JackCompiler::Parser::NodeTransformer.new(factory).visit(parse_tree)
      end

      def extract!
        JackCompiler::Transformer::NodeExtractor.new.visit(ast)
      end

      def to_s
        JackCompiler::Transformer::SimpleFormatter.new.visit(ast)
      end
    end
  end
end
