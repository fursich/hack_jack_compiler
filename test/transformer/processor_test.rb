require 'test_helper'

module JackCompiler
  module Transformer
    class TestParserProcessor < Minitest::Test
      def test_analyze_symbols
        parse_node = VisitorTestHelper.prepare_tree(<<~SOURCE, root_node: :class)
          class Bill {
            static integer tax_rate;
            field  integer total;
            field  String  contact_name;

            constructor Bill new(String name) {
              let total = 0;
              let contact_name = name;
              return this;
            }

            function void set_tax_rate(integer rate) {
              let tax_rate = rate;
            }

            method void add(Product prod, integer count) {
              var integer price;
              let price = prod.price();
              let total = price * count;
              return;
            }

            method integer summarize() {
              var Float gross;
              let gross = Math.to_float(total * (100 +tax_rate)) / Math.to_float(100);
              return Math.floor(gross);
            }
          }
        SOURCE

        processor = JackCompiler::Transformer::Processor.new(parse_node)
        processor.transform!
        processor.analyze_symbols
        table = processor.symbol_table

        assert_equal :Bill, table.class_name

        subroutines = table.subroutine_ids
        assert_equal %i(new set_tax_rate add summarize), subroutines.keys
        assert_equal [:constructor, :Bill],
          [
            subroutines[:new].kind,
            subroutines[:new].return_type,
          ]
        assert_equal [:function, :void],
          [
            subroutines[:set_tax_rate].kind,
            subroutines[:set_tax_rate].return_type,
          ]
        assert_equal [:method, :void],
          [
            subroutines[:add].kind,
            subroutines[:add].return_type,
          ]
        assert_equal [:method, :integer],
          [
            subroutines[:summarize].kind,
            subroutines[:summarize].return_type,
          ]

        # for class vars
        registered_vars = table.variable_ids[:class]
        assert_equal 3, registered_vars.size
        assert_equal [:static, :integer, 0],
          [
            registered_vars[:tax_rate].kind,
            registered_vars[:tax_rate].type,
            registered_vars[:tax_rate].number,
          ]
        assert_equal [:field, :integer, 0],
          [
            registered_vars[:total].kind,
            registered_vars[:total].type,
            registered_vars[:total].number,
          ]
        assert_equal [:field, :String, 1],
          [
            registered_vars[:contact_name].kind,
            registered_vars[:contact_name].type,
            registered_vars[:contact_name].number,
          ]

        # for .new
        registered_vars = table.variable_ids[:new]
        assert_equal 1, registered_vars.size
        assert_equal [:argument, :String, 0],
          [
            registered_vars[:name].kind,
            registered_vars[:name].type,
            registered_vars[:name].number,
          ]

        # for .set_tax_rate
        registered_vars = table.variable_ids[:set_tax_rate]
        assert_equal 1, registered_vars.size
        assert_equal [:argument, :integer, 0],
          [
            registered_vars[:rate].kind,
            registered_vars[:rate].type,
            registered_vars[:rate].number,
          ]

        # for #add
        registered_vars = table.variable_ids[:add]
        assert_equal 4, registered_vars.size
        assert_equal [:argument, :Bill, 0],
          [
            registered_vars[:this].kind,
            registered_vars[:this].type,
            registered_vars[:this].number,
          ]
        assert_equal [:argument, :Product, 1],
          [
            registered_vars[:prod].kind,
            registered_vars[:prod].type,
            registered_vars[:prod].number,
          ]
        assert_equal [:argument, :integer, 2],
          [
            registered_vars[:count].kind,
            registered_vars[:count].type,
            registered_vars[:count].number,
          ]
        assert_equal [:local, :integer, 0],
          [
            registered_vars[:price].kind,
            registered_vars[:price].type,
            registered_vars[:price].number,
          ]

        # for #summarize
        registered_vars = table.variable_ids[:summarize]
        assert_equal 2, registered_vars.size
        assert_equal [:argument, :Bill, 0],
          [
            registered_vars[:this].kind,
            registered_vars[:this].type,
            registered_vars[:this].number,
          ]
        assert_equal [:local, :Float, 0],
          [
            registered_vars[:gross].kind,
            registered_vars[:gross].type,
            registered_vars[:gross].number,
          ]
      end
    end
  end
end
