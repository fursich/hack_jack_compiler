require 'test_helper'

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
      end

      def self.append_children(node, count, category: :variable, kind: :term, value: nil)
        count.times do
          append_child(node, category: category, kind: kind, value: value)
        end
      end

      def self.build_descendants(node, count:, depth:, kind:, value:)
        if depth > 1
          append_children(node, count, category: :variable, kind: kind)
        elsif depth == 1
          append_children(node, count, category: :terminal, kind: :identifier, value: value)
          return
        else
          raise RuntimeError, 'depth: must be greater than 0'
        end

        node.children.each do |child|
          build_descendants(child, count: count, depth: depth-1, kind: kind, value: value)
        end
      end
    end
    
    class TestVisitorParentConnector < Minitest::Test
      def test_parents
        root = VisitorTestHelper.build_variable(:expression)
        VisitorTestHelper.build_descendants(root, count: 2, depth: 3, kind: :term, value: :foo)

        assert_nil root.parent
        root.children.each do |child|
          assert_nil child.parent
          child.children.each do |grandchild|
            assert_nil grandchild.parent
            grandchild.children.each do |grandgrandchild|
              assert_nil grandgrandchild.parent
            end
          end
        end

        JackCompiler::Parser::ParentConnector.new.visit(root)

        assert_nil root.parent
        root.children.each do |child|
          assert_equal root, child.parent
          child.children.each do |grandchild|
            assert_equal child, grandchild.parent
            grandchild.children.each do |grandgrandchild|
              assert_equal grandchild, grandgrandchild.parent
            end
          end
        end
      end
    end
  end
end
