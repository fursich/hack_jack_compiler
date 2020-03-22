module JackCompiler
  module Parser
    module VisitorTestHelper
      def self.build_variable(kind)
        JackCompiler::Parser::Node::Variable.new(
          kind
        )
      end

      def self.build_terminal(kind, value, source_location: 123)
        JackCompiler::Parser::Node::Terminal.new(
          kind,
          value,
          source_location: source_location,
        )
      end

      def self.append_child(node, category: :variable, kind: :term, value: nil)
        child = if category == :variable
                  build_variable(kind)
                else
                  build_terminal(kind, value)
                end
        node.push child
        child
      end

      def self.prepare_parser(raw_source, filename: 'filename.jack')
        source    = JackCompiler::Source.new(filename).tap { |source| source.store!(raw_source) }
        tokenizer = JackCompiler::Tokenizer::Processor.new(source).tap(&:tokenize!)
        JackCompiler::Parser::Processor.new(tokenizer.tokens)
      end

      def self.prepare_tree(raw_source, root_node:, filename: 'filename.jack')
        parser = prepare_parser(raw_source, filename: filename)
        parser.send "parse_#{root_node}"
      end
    end
  end
end
