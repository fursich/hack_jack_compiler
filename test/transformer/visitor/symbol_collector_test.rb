require 'test_helper'

module JackCompiler
  module Transformer
    class TestVisitorSymbolCollector < Minitest::Test
      class DummyNode < OpenStruct
        def initialize(kind, scope:, descendants: [])
          super(kind: kind, scope: scope, descendants: descendants)
        end

        def accept(visitor)
          visitor.visit(self)
        end
      end

      def test_irrelevant_nodes
        term = DummyNode.new(:term, scope: :class, descendants: [])
        node = DummyNode.new(:expression, scope: :class, descendants: [term]) 

        symbol_table = SymbolTable.new
        JackCompiler::Transformer::SymbolCollector.new(symbol_table).visit(node)
        assert_empty symbol_table.subroutine_ids
        assert_empty symbol_table.variable_ids
      end

      def test_class
        node = DummyNode.new(:class, scope: :class, descendants: [])
        node.class_name = :FooBar

        symbol_table = SymbolTable.new
        JackCompiler::Transformer::SymbolCollector.new(symbol_table).visit(node)
        assert_empty symbol_table.subroutine_ids
        assert_empty symbol_table.variable_ids
        assert_equal :FooBar, symbol_table.class_name
      end

      def test_class_var_dec
        node1 = DummyNode.new(:classVarDec, scope: :class, descendants: [])
        node1.var_kind  = :static
        node1.type      = :integer
        node1.var_names = [:var1, :var2, :var3]

        node2 = DummyNode.new(:classVarDec, scope: :class, descendants: [])
        node2.var_kind  = :field
        node2.type      = :Array
        node2.var_names = [:arr1, :arr2]

        root = DummyNode.new(:class, scope: :class, descendants: [node1, node2])
        root.class_name = :klass_name

        symbol_table = SymbolTable.new
        JackCompiler::Transformer::SymbolCollector.new(symbol_table).visit(root)

        assert_equal [:class], symbol_table.variable_ids.keys
        registered_vars = symbol_table.variable_ids[:class]

        assert_equal 5, registered_vars.size
        assert_equal [:integer, :static, 0],
          [
            registered_vars[:var1].type,
            registered_vars[:var1].kind,
            registered_vars[:var1].number,
          ]
        assert_equal [:integer, :static, 1],
          [
            registered_vars[:var2].type,
            registered_vars[:var2].kind,
            registered_vars[:var2].number,
          ]
        assert_equal [:integer, :static, 2],
          [
            registered_vars[:var3].type,
            registered_vars[:var3].kind,
            registered_vars[:var3].number,
          ]
        assert_equal [:Array, :field, 0],
          [
            registered_vars[:arr1].type,
            registered_vars[:arr1].kind,
            registered_vars[:arr1].number,
          ]
        assert_equal [:Array, :field, 1],
          [
            registered_vars[:arr2].type,
            registered_vars[:arr2].kind,
            registered_vars[:arr2].number,
          ]
      end

      def test_subroutine
        param = DummyNode.new(:parameterList, scope: :loremipsum, descendants: [])
        param.parameters = {
          integer: :foo,
          Array:   :bar,
          boolean: :baz,
        }
        node = DummyNode.new(:subroutineDec, scope: :class, descendants: [param])
        node.subroutine_name = :loremipsum
        node.subroutine_kind = :method
        node.return_type     = :void

        symbol_table = SymbolTable.new
        JackCompiler::Transformer::SymbolCollector.new(symbol_table).visit(node)

        assert_equal :method,  symbol_table.subroutine_ids[:loremipsum].kind
        assert_equal :void,    symbol_table.subroutine_ids[:loremipsum].return_type

        assert_equal [:loremipsum], symbol_table.variable_ids.keys
        registered_vars = symbol_table.variable_ids[:loremipsum]
        assert_equal 4, registered_vars.size
        assert_equal [:Klass, :argument, 0],
          [
            registered_vars[:this].type,
            registered_vars[:this].kind,
            registered_vars[:this].number,
          ]
        assert_equal [:integer, :argument, 1],
          [
            registered_vars[:foo].type,
            registered_vars[:foo].kind,
            registered_vars[:foo].number,
          ]
        assert_equal [:Array, :argument, 2],
          [
            registered_vars[:bar].type,
            registered_vars[:bar].kind,
            registered_vars[:bar].number,
          ]
        assert_equal [:boolean, :argument, 3],
          [
            registered_vars[:baz].type,
            registered_vars[:baz].kind,
            registered_vars[:baz].number,
          ]
      end

      def test_var_dec
        node1 = DummyNode.new(:varDec, scope: :foo_func, descendants: [])
        node1.type      = :integer
        node1.var_names = [:var1, :var2, :var3]

        node2 = DummyNode.new(:varDec, scope: :foo_func, descendants: [])
        node2.type      = :String
        node2.var_names = [:str1, :str2]

        root = DummyNode.new(:subroutineBody, scope: :foo_func, descendants: [node1, node2])

        symbol_table = SymbolTable.new
        JackCompiler::Transformer::SymbolCollector.new(symbol_table).visit(root)

        assert_equal [:foo_func], symbol_table.variable_ids.keys
        registered_vars = symbol_table.variable_ids[:foo_func]

        assert_equal 5, registered_vars.size
        assert_equal [:integer, :local, 0],
          [
            registered_vars[:var1].type,
            registered_vars[:var1].kind,
            registered_vars[:var1].number,
          ]
        assert_equal [:integer, :local, 1],
          [
            registered_vars[:var2].type,
            registered_vars[:var2].kind,
            registered_vars[:var2].number,
          ]
        assert_equal [:integer, :local, 2],
          [
            registered_vars[:var3].type,
            registered_vars[:var3].kind,
            registered_vars[:var3].number,
          ]
        assert_equal [:String, :local, 3],
          [
            registered_vars[:str1].type,
            registered_vars[:str1].kind,
            registered_vars[:str1].number,
          ]
        assert_equal [:String, :local, 4],
          [
            registered_vars[:str2].type,
            registered_vars[:str2].kind,
            registered_vars[:str2].number,
          ]
      end
    end
  end
end
