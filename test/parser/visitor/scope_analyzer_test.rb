require 'test_helper'

module JackCompiler
  module Parser
    class TestVisitorScopeAnalyzer < Minitest::Test
      def test_top_level
        root = VisitorTestHelper.build_variable(:class)
        VisitorTestHelper.build_descendants(root, count: 2, depth: 3, kind: :classVarDec, value: :foo)
        JackCompiler::Parser::ParentConnector.new.visit(root)

        assert_nil root.scope
        root.children.each do |child|
          assert_nil child.scope
          child.children.each do |grandchild|
            assert_nil grandchild.scope
          end
        end

        JackCompiler::Parser::ScopeAnalyzer.new.visit(root)

        assert_equal :class, root.scope
        root.children.each do |child|
          assert_equal :class, child.scope
          child.children.each do |grandchild|
            assert_equal :class, grandchild.scope
          end
        end
      end

      def test_subtree_under_scope
        sub = VisitorTestHelper.build_variable(:subroutineDec)
        VisitorTestHelper.append_child(sub, category: :terminal, kind: :keyword, value: :function)
        VisitorTestHelper.append_child(sub, category: :terminal, kind: :keyword, value: :void)
        VisitorTestHelper.append_child(sub, category: :terminal, kind: :identifier, value: :loremipsum)
        VisitorTestHelper.append_child(sub, category: :terminal, kind: :symbol, value: :'(')
        VisitorTestHelper.append_child(sub, category: :terminal, kind: :keyword, value: :int)
        VisitorTestHelper.append_child(sub, category: :terminal, kind: :identifier, value: :arg1)
        VisitorTestHelper.append_child(sub, category: :terminal, kind: :symbol, value: :')')
        VisitorTestHelper.append_child(sub, category: :variable, kind: :subroutineBody)

        VisitorTestHelper.append_children(sub.children.last, 4, category: :variable, kind: :dummy)
        root = VisitorTestHelper.build_variable(:class)
        root.push sub

        JackCompiler::Parser::ParentConnector.new.visit(root)

        assert_nil root.scope
        assert_nil sub.scope
        sub.children.each do |child|
          assert_nil child.scope

          if child.is_a? JackCompiler::Parser::Node::Variable
            child.children.each do |grandchild|
              assert_nil grandchild.scope
            end
          end
        end

        JackCompiler::Parser::ScopeAnalyzer.new.visit(root)

        assert_equal :class, root.scope
        assert_equal :loremipsum, sub.scope
        sub.children.each do |child|
          assert_equal :loremipsum, child.scope

          if child.is_a? JackCompiler::Parser::Node::Variable
            child.children.each do |grandchild|
              assert_equal :loremipsum, grandchild.scope
            end
          end
        end
      end
    end
  end
end
