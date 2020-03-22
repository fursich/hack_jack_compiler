require 'test_helper'

module JackCompiler
  module Transformer
    class TestVisitorScopeAnalyzer < Minitest::Test
      class DummyNode
        attr_accessor :descendants, :parent, :scope
        attr_accessor :kind
        attr_accessor :subroutine_name

        def initialize(kind, *descendants)
          @kind = kind
          @descendants = descendants
        end

        def accept(visitor)
          visitor.visit(self)
        end
      end

      def test_scopes
        child1 = DummyNode.new(:child1, *3.times.map { DummyNode.new(:foo) })
        child2 = DummyNode.new(:subroutineDec, *3.times.map { DummyNode.new(:bar) })
        child2.subroutine_name = :loremipsum
        root   = DummyNode.new(:root, child1, child2)
        JackCompiler::Transformer::ParentConnector.new.visit(root)

        assert_nil root.scope
        root.descendants.each do |child|
          assert_nil child.scope
          child.descendants.each do |grandchild|
            assert_nil grandchild.scope
          end
        end

        JackCompiler::Transformer::ScopeAnalyzer.new.visit(root)

        assert_equal :class, root.scope

        child = root.descendants[0]
        assert_equal :class, child.scope
        child.descendants.each do |grandchild|
          assert_equal :class, grandchild.scope
        end

        child = root.descendants[1]
        assert_equal :loremipsum, child.scope
        child.descendants.each do |grandchild|
          assert_equal :loremipsum, grandchild.scope
        end
      end
    end
  end
end
