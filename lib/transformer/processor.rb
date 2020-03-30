require_relative 'node_factory'
require_relative 'symbol_table'
require_relative 'nodes/nodes'
require_relative 'visitor/visitor'

module JackCompiler
  module Transformer
    class Processor
      attr_reader :parse_tree, :factory, :symbol_table, :ast, :vm_code

      def initialize(parse_tree)
        @parse_tree = parse_tree
        @factory = NodeFactory
      end

      def transform!
        @ast = JackCompiler::Parser::NodeTransformer.new(factory).visit(parse_tree)
        JackCompiler::Transformer::NodeExtractor.new.visit(ast)
        ast
      end

      def to_s
        JackCompiler::Transformer::SimpleFormatter.new.visit(ast)
      end

      def analyze_symbols
        JackCompiler::Transformer::ParentConnector.new.visit(ast)
        JackCompiler::Transformer::ScopeAnalyzer.new.visit(ast)
        @symbol_table = SymbolTable.new
        JackCompiler::Transformer::SymbolCollector.new(symbol_table).visit(ast)
      end

      def compile
        @vm_code = JackCompiler::Transformer::Compiler.new(symbol_table).visit(ast)
      end

      def print
        vm_code.join("\n")
      end
    end
  end
end
