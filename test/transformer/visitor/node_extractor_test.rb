require 'test_helper'

module JackCompiler
  module Transformer
    class TestVisitorNodeExtractor < Minitest::Test
      def test_class
        node = VisitorTestHelper.prepare_tree(<<~SOURCE, root_node: :class)
          class Foo {
            field int x, y;
            field Array map;
          }
        SOURCE

        tree = JackCompiler::Parser::NodeTransformer.new(NodeFactory).visit(node)
        JackCompiler::Transformer::NodeExtractor.new.visit(tree)

        assert_equal :Foo, tree.class_name
        tree.class_var_decs.each do |node|
          assert_instance_of JackCompiler::Transformer::Node::ClassVarDec, node
        end
        tree.subroutine_decs.each do |node|
          assert_instance_of JackCompiler::Transformer::Node::SubroutineDec, node
        end
      end

      def test_class_var_dec
        node = VisitorTestHelper.prepare_tree(<<~SOURCE, root_node: :class_var_dec)
          static boolean foo, bar, baz;
        SOURCE

        tree = JackCompiler::Parser::NodeTransformer.new(NodeFactory).visit(node)
        JackCompiler::Transformer::NodeExtractor.new.visit(tree)

        assert_equal :static,            tree.var_kind
        assert_equal :boolean,           tree.type
        assert_equal [:foo, :bar, :baz], tree.var_names
      end

      def test_subroutine_dec
        node = VisitorTestHelper.prepare_tree(<<~SOURCE, root_node: :subroutine_dec)
          method int loremipsum(int arg1, bool arg2) {
            var int var1, var2, var3;
            let var1 = 1;
          }
        SOURCE

        tree = JackCompiler::Parser::NodeTransformer.new(NodeFactory).visit(node)
        JackCompiler::Transformer::NodeExtractor.new.visit(tree)

        assert_equal :method,     tree.subroutine_kind
        assert_equal :int,        tree.return_type
        assert_equal :loremipsum, tree.subroutine_name
        assert_instance_of JackCompiler::Transformer::Node::ParameterList, tree.parameter_list
        assert_instance_of JackCompiler::Transformer::Node::SubroutineBody, tree.subroutine_body
      end

      def test_parameter_list
        node = VisitorTestHelper.prepare_tree(<<~SOURCE, root_node: :parameter_list)
          int foo, boolean bar, Array baz
        SOURCE

        tree = JackCompiler::Parser::NodeTransformer.new(NodeFactory).visit(node)
        JackCompiler::Transformer::NodeExtractor.new.visit(tree)

        parameters = {
          int:     :foo,
          boolean: :bar,
          Array:   :baz
        }
        assert_equal parameters, tree.parameters
      end

      def test_subroutine_body
        node = VisitorTestHelper.prepare_tree(<<~SOURCE, root_node: :subroutine_body)
          {
            var Array foo;
            var int bar;
            var boolean boo;
            let foo = Array.new(10);
            let bar = 0;
            let boo = true;
            while(boo) {
              do foo.calc(bar);
              if(foo.foo_size() > 5) {
                let boo = false;
              }
              let bar = bar -1;
            }
            return bar;
          }
        SOURCE

        tree = JackCompiler::Parser::NodeTransformer.new(NodeFactory).visit(node)
        JackCompiler::Transformer::NodeExtractor.new.visit(tree)

        assert_equal 3, tree.var_decs.count
        tree.var_decs.each do |node|
          assert_instance_of JackCompiler::Transformer::Node::VarDec, node
        end
        assert_equal 5, tree.statements.count
        assert_instance_of JackCompiler::Transformer::Node::LetStatement,    tree.statements[0]
        assert_instance_of JackCompiler::Transformer::Node::LetStatement,    tree.statements[1]
        assert_instance_of JackCompiler::Transformer::Node::LetStatement,    tree.statements[2]
        assert_instance_of JackCompiler::Transformer::Node::WhileStatement,  tree.statements[3]
        assert_instance_of JackCompiler::Transformer::Node::ReturnStatement, tree.statements[4]
      end

      def test_var_dec
        node = VisitorTestHelper.prepare_tree(<<~SOURCE, root_node: :var_dec)
          var Array foo, bar, baz, boo;
        SOURCE

        tree = JackCompiler::Parser::NodeTransformer.new(NodeFactory).visit(node)
        JackCompiler::Transformer::NodeExtractor.new.visit(tree)

        assert_equal :Array, tree.type
        assert_equal %i(foo bar baz boo), tree.var_names
      end

      def test_let_statement
        node = VisitorTestHelper.prepare_tree(<<~SOURCE, root_node: :let_statement)
          let foo[bar * x + 2] = x;
        SOURCE

        tree = JackCompiler::Parser::NodeTransformer.new(NodeFactory).visit(node)
        JackCompiler::Transformer::NodeExtractor.new.visit(tree)

        assert_instance_of JackCompiler::Transformer::Node::VariableAccess, tree.var
        assert_equal       :foo,                                            tree.var.name
        assert_instance_of JackCompiler::Transformer::Node::Expression,     tree.var.index
        assert_instance_of JackCompiler::Transformer::Node::Expression,     tree.rvalue
      end

      def test_if_statement
        node = VisitorTestHelper.prepare_tree(<<~SOURCE, root_node: :if_statement)
          if(foo + bar = 10) {
            do func(i, t);
            let i[2] = t / 2;
          }
          else {
            let i[0] = t * 2;
          }
        SOURCE

        tree = JackCompiler::Parser::NodeTransformer.new(NodeFactory).visit(node)
        JackCompiler::Transformer::NodeExtractor.new.visit(tree)

        assert_instance_of JackCompiler::Transformer::Node::Expression,   tree.condition
        assert_equal       2, tree.if_statements.size
        assert_instance_of JackCompiler::Transformer::Node::DoStatement,  tree.if_statements[0]
        assert_instance_of JackCompiler::Transformer::Node::LetStatement, tree.if_statements[1]
        assert_equal       1, tree.else_statements.size
        assert_instance_of JackCompiler::Transformer::Node::LetStatement, tree.else_statements[0]

        node = VisitorTestHelper.prepare_tree(<<~SOURCE, root_node: :if_statement)
          if(foo + bar = 10) {
            let i[2] = t / 2;
          }
        SOURCE

        tree = JackCompiler::Parser::NodeTransformer.new(NodeFactory).visit(node)
        JackCompiler::Transformer::NodeExtractor.new.visit(tree)

        assert_instance_of JackCompiler::Transformer::Node::Expression,   tree.condition
        assert_equal       1, tree.if_statements.size
        assert_instance_of JackCompiler::Transformer::Node::LetStatement, tree.if_statements[0]
        assert_nil         tree.else_statements
      end

      def test_while_statement
        node = VisitorTestHelper.prepare_tree(<<~SOURCE, root_node: :while_statement)
          while(foo < (bar / 10)) {
            do func(i, t);
            let i = i * 10;
          }
        SOURCE

        tree = JackCompiler::Parser::NodeTransformer.new(NodeFactory).visit(node)
        JackCompiler::Transformer::NodeExtractor.new.visit(tree)

        assert_instance_of JackCompiler::Transformer::Node::Expression,   tree.condition
        assert_equal       2, tree.while_statements.size
        assert_instance_of JackCompiler::Transformer::Node::DoStatement,  tree.while_statements[0]
        assert_instance_of JackCompiler::Transformer::Node::LetStatement, tree.while_statements[1]
      end

      def test_do_statement
        node = VisitorTestHelper.prepare_tree(<<~SOURCE, root_node: :do_statement)
          do foo_func();
        SOURCE

        tree = JackCompiler::Parser::NodeTransformer.new(NodeFactory).visit(node)
        JackCompiler::Transformer::NodeExtractor.new.visit(tree)

        assert_instance_of JackCompiler::Transformer::Node::SubroutineCall, tree.subroutine_call

        node = VisitorTestHelper.prepare_tree(<<~SOURCE, root_node: :do_statement)
          do bar_func("string", false);
        SOURCE

        tree = JackCompiler::Parser::NodeTransformer.new(NodeFactory).visit(node)
        JackCompiler::Transformer::NodeExtractor.new.visit(tree)

        assert_instance_of JackCompiler::Transformer::Node::SubroutineCall, tree.subroutine_call

        node = VisitorTestHelper.prepare_tree(<<~SOURCE, root_node: :do_statement)
          do arr.replace(1, "foo", true);
        SOURCE

        tree = JackCompiler::Parser::NodeTransformer.new(NodeFactory).visit(node)
        JackCompiler::Transformer::NodeExtractor.new.visit(tree)

        assert_instance_of JackCompiler::Transformer::Node::SubroutineCall, tree.subroutine_call
      end

      def test_return_statement
        node = VisitorTestHelper.prepare_tree(<<~SOURCE, root_node: :return_statement)
          return;
        SOURCE

        tree = JackCompiler::Parser::NodeTransformer.new(NodeFactory).visit(node)
        JackCompiler::Transformer::NodeExtractor.new.visit(tree)

        assert_nil tree.return_value

        node = VisitorTestHelper.prepare_tree(<<~SOURCE, root_node: :return_statement)
          return this;
        SOURCE

        tree = JackCompiler::Parser::NodeTransformer.new(NodeFactory).visit(node)
        JackCompiler::Transformer::NodeExtractor.new.visit(tree)

        assert_instance_of JackCompiler::Transformer::Node::Expression, tree.return_value
      end

      def test_expression
        node = VisitorTestHelper.prepare_tree(<<~SOURCE, root_node: :expression)
          baz(10) = 2 + foo - bar[12] * boo/3
        SOURCE

        tree = JackCompiler::Parser::NodeTransformer.new(NodeFactory).visit(node)
        JackCompiler::Transformer::NodeExtractor.new.visit(tree)

        assert_instance_of JackCompiler::Transformer::Node::Expression,   tree

        assert_instance_of JackCompiler::Transformer::Node::Term,         tree.lvalue
        assert_equal       :'=',                                          tree.op
        assert_instance_of JackCompiler::Transformer::Node::Expression,   tree.rvalue

        node = tree.rvalue
        assert_instance_of JackCompiler::Transformer::Node::Term,         node.lvalue
        assert_equal       :'+',                                          node.op
        assert_instance_of JackCompiler::Transformer::Node::Expression,   node.rvalue

        node = node.rvalue
        assert_instance_of JackCompiler::Transformer::Node::Term,         node.lvalue
        assert_equal       :'-',                                          node.op
        assert_instance_of JackCompiler::Transformer::Node::Expression,   node.rvalue

        node = node.rvalue
        assert_instance_of JackCompiler::Transformer::Node::Term,         node.lvalue
        assert_equal       :'*',                                          node.op
        assert_instance_of JackCompiler::Transformer::Node::Expression,   node.rvalue

        node = node.rvalue
        assert_instance_of JackCompiler::Transformer::Node::Term,         node.lvalue
        assert_equal       :'/',                                          node.op
        assert_instance_of JackCompiler::Transformer::Node::Expression,   node.rvalue

        node = node.rvalue
        assert_instance_of JackCompiler::Transformer::Node::Term,         node.lvalue
        assert_nil                                                        node.op
        assert_nil                                                        node.rvalue
      end

      def test_term
        node = VisitorTestHelper.prepare_tree(<<~SOURCE, root_node: :term)
          (foo + 2)
        SOURCE

        tree = JackCompiler::Parser::NodeTransformer.new(NodeFactory).visit(node)
        JackCompiler::Transformer::NodeExtractor.new.visit(tree)

        assert_instance_of JackCompiler::Transformer::Node::Expression,     tree.sub_node

        node = tree.sub_node
        assert_instance_of JackCompiler::Transformer::Node::Term,           node.lvalue
        assert_equal       :'+',                                            node.op
        assert_instance_of JackCompiler::Transformer::Node::Expression,     node.rvalue

        term = node.lvalue
        assert_instance_of JackCompiler::Transformer::Node::VariableAccess, term.sub_node
        assert_equal       :foo,                                            term.sub_node.name
        assert_nil                                                          term.sub_node.index

        term = node.rvalue.lvalue
        assert_instance_of JackCompiler::Transformer::Node::Terminal,       term.sub_node
        assert_equal       2,                                               term.sub_node.value
      end

      def test_subroutine_call
        node = VisitorTestHelper.prepare_tree(<<~SOURCE, root_node: :term)
          foo_func()
        SOURCE

        tree = JackCompiler::Parser::NodeTransformer.new(NodeFactory).visit(node)
        JackCompiler::Transformer::NodeExtractor.new.visit(tree)
        node = tree.sub_node

        assert_nil                                                        node.receiver_name
        assert_equal       :subroutineCall,                               node.kind
        assert_equal       :foo_func,                                     node.subroutine_name
        assert_empty                                                      node.arguments

        node = VisitorTestHelper.prepare_tree(<<~SOURCE, root_node: :term)
          bar_func("string", false)
        SOURCE

        tree = JackCompiler::Parser::NodeTransformer.new(NodeFactory).visit(node)
        JackCompiler::Transformer::NodeExtractor.new.visit(tree)
        node = tree.sub_node

        assert_nil                                                        node.receiver_name
        assert_equal       :subroutineCall,                               node.kind
        assert_equal       :bar_func,                                     node.subroutine_name
        assert_equal       2, node.arguments.size
        node.arguments.each do |arg|
          assert_instance_of JackCompiler::Transformer::Node::Expression, arg
        end

        node = VisitorTestHelper.prepare_tree(<<~SOURCE, root_node: :term)
          arr.replace(1, "foo", true)
        SOURCE

        tree = JackCompiler::Parser::NodeTransformer.new(NodeFactory).visit(node)
        JackCompiler::Transformer::NodeExtractor.new.visit(tree)
        node = tree.sub_node

        assert_equal       :arr,                                          node.receiver_name
        assert_equal       :subroutineCall,                               node.kind
        assert_equal       :replace,                                      node.subroutine_name
        assert_equal       3, node.arguments.size
        node.arguments.each do |arg|
          assert_instance_of JackCompiler::Transformer::Node::Expression, arg
        end
      end

      def test_unary_op
        node = VisitorTestHelper.prepare_tree(<<~SOURCE, root_node: :term)
          -foo.bar(baz, 10)
        SOURCE

        tree = JackCompiler::Parser::NodeTransformer.new(NodeFactory).visit(node)
        JackCompiler::Transformer::NodeExtractor.new.visit(tree)
        node = tree.sub_node

        assert_instance_of JackCompiler::Transformer::Node::UnaryOp,      node
        assert_equal       :unaryOp,                                      node.kind
        assert_equal       :-,                                            node.op
        assert_instance_of JackCompiler::Transformer::Node::Term,         node.term
      end

      def test_variable_access
        node = VisitorTestHelper.prepare_tree(<<~SOURCE, root_node: :term)
          foo[10-bar]
        SOURCE

        tree = JackCompiler::Parser::NodeTransformer.new(NodeFactory).visit(node)
        JackCompiler::Transformer::NodeExtractor.new.visit(tree)
        node = tree.sub_node

        assert_instance_of JackCompiler::Transformer::Node::VariableAccess, node
        assert_equal       :variableAccess,                                 node.kind
        assert_equal       :get,                                            node.mode
        assert_equal       :foo,                                            node.name
        assert_instance_of JackCompiler::Transformer::Node::Expression,     node.index

        node = VisitorTestHelper.prepare_tree(<<~SOURCE, root_node: :let_statement)
          let bar[100] = x;
        SOURCE

        tree = JackCompiler::Parser::NodeTransformer.new(NodeFactory).visit(node)
        JackCompiler::Transformer::NodeExtractor.new.visit(tree)
        node = tree.var

      assert_instance_of JackCompiler::Transformer::Node::VariableAccess, node
      assert_equal       :variableAccess,                                 node.kind
      assert_equal       :set,                                            node.mode
      assert_equal       :bar,                                            node.name
      assert_instance_of JackCompiler::Transformer::Node::Expression,     node.index
      end
    end
  end
end
