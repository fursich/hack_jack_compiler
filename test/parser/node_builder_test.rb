require 'test_helper'

module JackCompiler
  module Parser
    class TestParserNodeBuilder < Minitest::Test
      def test_build_variable
        node = JackCompiler::Parser::NodeBuilder.build_variable(:foo_type)
        assert_instance_of JackCompiler::Parser::Node::Variable, node
        assert_equal :foo_type, node.type
        assert_empty node.children
      end

      def test_build_terminal
        token = JackCompiler::Tokenizer::Token.new(
          :keyword,
          :return,
          source_location: :test_location
        )

        node = JackCompiler::Parser::NodeBuilder.build_terminal(token)
        assert_instance_of JackCompiler::Parser::Node::Terminal, node
        assert_equal token.type, node.type
        assert_equal token.value, node.value
        assert_equal token.source_location, node.source_location
      end

      def test_register_as_terminal
        parent_node = JackCompiler::Parser::NodeBuilder.build_variable(:foo_type)
        context = JackCompiler::Parser::Context.new
        context.parents << parent_node

        token = JackCompiler::Tokenizer::Token.new(
          :integer,
          12345,
          source_location: :fake_location
        )

        JackCompiler::Parser::NodeBuilder.register_as_terminal(token, context)

        node = parent_node.children.last

        assert_instance_of JackCompiler::Parser::Node::Terminal, node
        assert_equal token.type, node.type
        assert_equal token.value, node.value
        assert_equal token.source_location, node.source_location
      end
    end
  end
end
