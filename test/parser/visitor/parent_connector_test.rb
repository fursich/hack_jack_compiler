require 'test_helper'

module JackCompiler
  module Parser
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
