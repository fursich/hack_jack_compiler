require 'test_helper'

module JackCompiler
  module Transformer
    class TestVisitorParentConnector < Minitest::Test
      class DummyNode
        attr_accessor :descendants, :parent

        def initialize(*descendants)
          @descendants = descendants
        end

        def accept(visitor)
          visitor.visit(self)
        end
      end

      def test_parents
        child1 = DummyNode.new(*3.times.map { DummyNode.new })
        child2 = DummyNode.new(*3.times.map { DummyNode.new })
        root   = DummyNode.new(child1, child2)

        assert_nil root.parent
        root.descendants.each do |child|
          assert_nil child.parent
          child.descendants.each do |grandchild|
            assert_nil grandchild.parent
          end
        end

        JackCompiler::Transformer::ParentConnector.new.visit(root)

        assert_nil root.parent
        root.descendants.each do |child|
          assert_equal root, child.parent
          child.descendants.each do |grandchild|
            assert_equal child, grandchild.parent
          end
        end
      end
    end
  end
end
