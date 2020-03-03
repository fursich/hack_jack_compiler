require 'test_helper'

module JackCompiler
  module Parser
    module ContextTestHelper
      def self.with_new_context(&block)
        context = JackCompiler::Parser::Context.new

        block.call context
      end
    end

    class TestParserContext < Minitest::Test
      def test_parents
        ContextTestHelper.with_new_context do |context|
          assert_empty context.parents
          context.parents << '11111'
          context.parents << :xxxxx

          assert_equal ['11111', :xxxxx], context.parents
        end
      end

      def test_current_parent
        ContextTestHelper.with_new_context do |context|
          assert_nil context.current_parent

          context.parents << :foo
          assert_equal :foo, context.current_parent

          context.parents << :bar
          assert_equal :bar, context.current_parent
        end
      end

      def test_link
        parent_node  = JackCompiler::Parser::Node::Variable.new(:foo_kind)
        first_child  = JackCompiler::Parser::Node::Variable.new(:child1)
        second_child = JackCompiler::Parser::Node::Terminal.new(:child2, 123, source_location: :fake_location)

        ContextTestHelper.with_new_context do |context|
          context.parents << parent_node

          context.link!(first_child)
          assert_equal [first_child], parent_node.children

          context.link!(second_child)
          assert_equal [first_child, second_child], parent_node.children
        end
      end

      def test_execute_with
        parent_node = JackCompiler::Parser::Node::Variable.new(:foo_kind)
        child_node  = JackCompiler::Parser::Node::Variable.new(:child)
        grand_child = JackCompiler::Parser::Node::Variable.new(:grand_child)

        ContextTestHelper.with_new_context do |context|
          context.parents << parent_node

          assert_equal parent_node, context.current_parent
          assert_empty parent_node.children
          assert_empty child_node.children

          context.execute_with(child_node) do
            assert_equal child_node, context.current_parent

            context.execute_with(grand_child) do
              assert_equal grand_child, context.current_parent
            end

            assert_equal child_node, context.current_parent
          end

          assert_equal parent_node, context.current_parent
          assert_equal [child_node], parent_node.children
          assert_equal [grand_child], child_node.children
        end
      end
    end
  end
end
