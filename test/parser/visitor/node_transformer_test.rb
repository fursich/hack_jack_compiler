require 'test_helper'

module JackCompiler
  module Parser
    class TestVisitorNodeTransformer < Minitest::Test
      class DummyFactory
        attr_reader :kind, :options
        def initialize(kind)
          @kind = kind
        end

        def build(**options)
          @options = options

          self
        end
      end

      def xtest_class
        node = VisitorTestHelper.prepare_tree(<<~SOURCE, root_node: :class)
          class Foo {
            field int x, y;
            field Array map;
          }
        SOURCE

        factory = DummyFactory
        tree = JackCompiler::Parser::NodeTransformer.new(factory).visit(node)
        binding.pry
      end

      def xtest_noderoutine
        node = VisitorTestHelper.prepare_tree(<<~SOURCE, root_node: :subroutine_dec)
          method int loremipsum(int arg1, bool arg2) {
            var int var1, var2, var3;
            let var1 = 1;
          }
        SOURCE

        factory = DummyFactory
        tree = JackCompiler::Parser::NodeTransformer.new(factory).visit(node)
        binding.pry
      end

      def xtest_let_statement
        node = VisitorTestHelper.prepare_tree(<<~SOURCE, root_node: :let_statement)
          let foo[bar * x + 2] = x;
        SOURCE

        statement = VisitorTestHelper.build_variable(:statement)
        statement.push node

        factory = DummyFactory
        tree = JackCompiler::Parser::NodeTransformer.new(factory).visit(statement)
        binding.pry
      end

      def xtest_if_statement
        node = VisitorTestHelper.prepare_tree(<<~SOURCE, root_node: :if_statement)
          if(foo + bar = 10) {
            let i[2] = t / 2;
          }
          else {
            let i[0] = t * 2;
          }
        SOURCE

        statement = VisitorTestHelper.build_variable(:statement)
        statement.push node

        factory = DummyFactory
        tree = JackCompiler::Parser::NodeTransformer.new(factory).visit(statement)
        binding.pry
      end

      def xtest_while_statement
        node = VisitorTestHelper.prepare_tree(<<~SOURCE, root_node: :while_statement)
          while(foo < (bar / 10)) {
            let i = i * 10;
          }
        SOURCE

        statement = VisitorTestHelper.build_variable(:statement)
        statement.push node

        factory = DummyFactory
        tree = JackCompiler::Parser::NodeTransformer.new(factory).visit(statement)
        binding.pry
      end

      def xtest_do_statement
        node = VisitorTestHelper.prepare_tree(<<~SOURCE, root_node: :do_statement)
          do foo.reverse();
        SOURCE

        statement = VisitorTestHelper.build_variable(:statement)
        statement.push node

        factory = DummyFactory
        tree = JackCompiler::Parser::NodeTransformer.new(factory).visit(statement)
        binding.pry
      end

      def xtest_return_statement
        node = VisitorTestHelper.prepare_tree(<<~SOURCE, root_node: :return_statement)
          return this;
        SOURCE

        statement = VisitorTestHelper.build_variable(:statement)
        statement.push node

        factory = DummyFactory
        tree = JackCompiler::Parser::NodeTransformer.new(factory).visit(statement)
        binding.pry
      end

      def xtest_expression
        node = VisitorTestHelper.prepare_tree(<<~SOURCE, root_node: :expression)
          (1 + (foo * bar[12]) / 2 = baz(10)) & Foo.func("a random string") | ~( var0 < var1 ) & (var2 = var3) | false & true;
        SOURCE

        factory = DummyFactory
        tree = JackCompiler::Parser::NodeTransformer.new(factory).visit(node)
        binding.pry
      end
    end
  end
end
