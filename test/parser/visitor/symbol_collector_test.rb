require 'test_helper'

module JackCompiler
  module Parser
    class TestVisitorSymbolCollector < Minitest::Test
      def test_irrelevant_nodes
        root = VisitorTestHelper.build_variable(:expression)
        VisitorTestHelper.build_descendants(root, count: 2, depth: 3, kind: :term, value: :foo)
        JackCompiler::Parser::ParentConnector.new.visit(root)
        JackCompiler::Parser::ScopeAnalyzer.new.visit(root)

        symbol_table = SymbolTable.new(:Klass)
        JackCompiler::Parser::SymbolCollector.new(symbol_table).visit(root)
        assert_empty symbol_table.subroutine_ids
        assert_empty symbol_table.variable_ids
      end

      def test_class_var_dec
        dec1 = VisitorTestHelper.prepare_class_var_dec(
          :field,
          :String,
          :str1,
          :str2,
          :str3,
        )
        dec2 = VisitorTestHelper.prepare_class_var_dec(
          :static,
          :integer,
          :var1,
          :var2,
          :var3,
        )
        dec3 = VisitorTestHelper.prepare_class_var_dec(
          :field,
          :boolean,
          :fl1,
          :fl2,
        )
        root = VisitorTestHelper.build_variable(:class)
        VisitorTestHelper.append_child(root, category: :terminal, kind: :keyword, value: :class)
        VisitorTestHelper.append_child(root, category: :terminal, kind: :identifier, value: :Klass)

        VisitorTestHelper.append_child(root, category: :terminal, kind: :symbol, value: :'{')
        root.push dec1
        root.push dec2
        root.push dec3
        VisitorTestHelper.append_child(root, category: :terminal, kind: :symbol, value: :'}')

        JackCompiler::Parser::ParentConnector.new.visit(root)
        JackCompiler::Parser::ScopeAnalyzer.new.visit(root)

        symbol_table = SymbolTable.new(:Klass)
        JackCompiler::Parser::SymbolCollector.new(symbol_table).visit(root)

        assert_empty symbol_table.subroutine_ids

        assert_equal [:class], symbol_table.variable_ids.keys
        registered_vars = symbol_table.variable_ids[:class]
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
        assert_equal [:String, :field, 0],
          [
            registered_vars[:str1].type,
            registered_vars[:str1].kind,
            registered_vars[:str1].number,
          ]
        assert_equal [:String, :field, 1],
          [
            registered_vars[:str2].type,
            registered_vars[:str2].kind,
            registered_vars[:str2].number,
          ]
        assert_equal [:String, :field, 2],
          [
            registered_vars[:str3].type,
            registered_vars[:str3].kind,
            registered_vars[:str3].number,
          ]
        assert_equal [:boolean, :field, 3],
          [
            registered_vars[:fl1].type,
            registered_vars[:fl1].kind,
            registered_vars[:fl1].number,
          ]
        assert_equal [:boolean, :field, 4],
          [
            registered_vars[:fl2].type,
            registered_vars[:fl2].kind,
            registered_vars[:fl2].number,
          ]
      end

      def test_subroutine
        sub = VisitorTestHelper.prepare_subroutine(
          :loremipsum,
          :method,
          :integer,
          var1: :integer,
          var2: :String,
          var3: :boolean,
        )
        root = VisitorTestHelper.build_variable(:class)
        root.push sub

        JackCompiler::Parser::ParentConnector.new.visit(root)
        JackCompiler::Parser::ScopeAnalyzer.new.visit(root)

        symbol_table = SymbolTable.new(:Klass)
        JackCompiler::Parser::SymbolCollector.new(symbol_table).visit(root)

        assert_equal :method,  symbol_table.subroutine_ids[:loremipsum].kind
        assert_equal :integer, symbol_table.subroutine_ids[:loremipsum].return_type

        assert_equal [:loremipsum], symbol_table.variable_ids.keys
        registered_vars = symbol_table.variable_ids[:loremipsum]
        assert_equal [:Klass, :argument, 0],
          [
            registered_vars[:this].type,
            registered_vars[:this].kind,
            registered_vars[:this].number,
          ]
        assert_equal [:integer, :argument, 1],
          [
            registered_vars[:var1].type,
            registered_vars[:var1].kind,
            registered_vars[:var1].number,
          ]
        assert_equal [:String, :argument, 2],
          [
            registered_vars[:var2].type,
            registered_vars[:var2].kind,
            registered_vars[:var2].number,
          ]
        assert_equal [:boolean, :argument, 3],
          [
            registered_vars[:var3].type,
            registered_vars[:var3].kind,
            registered_vars[:var3].number,
          ]
      end

      def test_var_dec
        sub = VisitorTestHelper.prepare_subroutine(
          :loremipsum,
          :function,
        )
        dec1 = VisitorTestHelper.prepare_var_dec(
          :integer,
          :var1,
          :var2,
          :var3,
        )
        dec2 = VisitorTestHelper.prepare_var_dec(
          :String,
          :str1,
          :str2,
          :str3,
        )
        sub.push dec1
        sub.push dec2

        root = VisitorTestHelper.build_variable(:class)
        root.push sub

        JackCompiler::Parser::ParentConnector.new.visit(root)
        JackCompiler::Parser::ScopeAnalyzer.new.visit(root)

        symbol_table = SymbolTable.new(:Klass)
        JackCompiler::Parser::SymbolCollector.new(symbol_table).visit(root)

        assert_equal :function, symbol_table.subroutine_ids[:loremipsum].kind
        assert_equal :void,   symbol_table.subroutine_ids[:loremipsum].return_type

        assert_equal [:loremipsum], symbol_table.variable_ids.keys
        registered_vars = symbol_table.variable_ids[:loremipsum]
        assert_equal [:Klass, :argument, 0],
          [
            registered_vars[:this].type,
            registered_vars[:this].kind,
            registered_vars[:this].number,
          ]
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
        assert_equal [:String, :local, 5],
          [
            registered_vars[:str3].type,
            registered_vars[:str3].kind,
            registered_vars[:str3].number,
          ]
      end
    end
  end
end
