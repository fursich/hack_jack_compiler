require 'test_helper'

module JackCompiler
  module Transformer
    module SymbolTableTestHelper
      def self.with_new_table(class_name: nil, &block)
        symbol_table = JackCompiler::Transformer::SymbolTable.new
        if class_name
          symbol_table.instance_eval do
            @class_name = class_name
          end
        end

        block.call symbol_table
      end
    end

    class TestSymbolTable < Minitest::Test
      def test_initialize
        SymbolTableTestHelper.with_new_table do |table|
          assert_equal :Klass, table.class_name
          assert_empty         table.subroutine_ids
          assert_empty         table.variable_ids
        end
      end

      def test_register_class
        SymbolTableTestHelper.with_new_table do |table|
          assert_equal :Klass, table.class_name # default

          table.register_class(:FooBar)

          assert_equal :FooBar, table.class_name # default
        end
      end

      def test_register_constructor
        SymbolTableTestHelper.with_new_table(class_name: :ClassName) do |table|
          assert_nil   table.subroutine_ids[:constructor_name]
          assert_nil   table.variable_ids[:constructor_name]

          table.register_subroutine(:constructor_name, kind: :constructor, return_type: :class_name)

          subroutine_desc = table.subroutine_ids[:constructor_name]
          var_desc        = table.variable_ids[:constructor_name]

          refute_nil   subroutine_desc
          assert_empty var_desc
          assert_equal 0, table.size_of(:argument, scope: :constructor_name)

          assert_equal :constructor, subroutine_desc.kind
          assert_equal :class_name,  subroutine_desc.return_type
        end
      end

      def test_register_function
        SymbolTableTestHelper.with_new_table(class_name: :ClassName) do |table|
          assert_nil   table.subroutine_ids[:function_name]
          assert_nil   table.variable_ids[:function_name]

          table.register_subroutine(:function_name, kind: :function, return_type: :boolean)

          subroutine_desc = table.subroutine_ids[:function_name]
          var_desc        = table.variable_ids[:function_name]

          refute_nil   subroutine_desc
          assert_empty var_desc
          assert_equal 0, table.size_of(:argument, scope: :function_name)

          assert_equal :function,    subroutine_desc.kind
          assert_equal :boolean,     subroutine_desc.return_type
        end
      end

      def test_register_method
        SymbolTableTestHelper.with_new_table(class_name: :ClassName) do |table|
          assert_nil   table.subroutine_ids[:method_name]
          assert_nil   table.variable_ids[:method_name]

          table.register_subroutine(:method_name, kind: :method, return_type: :integer)

          subroutine_desc = table.subroutine_ids[:method_name]
          var_desc        = table.variable_ids[:method_name]

          refute_nil   subroutine_desc
          refute_empty var_desc

          assert_equal :method,      subroutine_desc.kind
          assert_equal :integer,     subroutine_desc.return_type
          assert_equal 1, table.size_of(:argument, scope: :method_name)

          assert_equal [:this],      var_desc.keys
          assert_equal :argument,    var_desc[:this].kind
          assert_equal :ClassName,   var_desc[:this].type
        end
      end

      def test_register_duplicated_subroutines
        SymbolTableTestHelper.with_new_table do |table|
          table.register_subroutine(:method_name, kind: :method, return_type: :integer)

          assert_raises(RuntimeError) {
            table.register_subroutine(:method_name, kind: :function, return_type: :void)
          }
        end
      end

      def test_variables_static
        SymbolTableTestHelper.with_new_table do |table|
          assert_empty           table.variable_ids

          table.register_variable(:bar, kind: :static, type: :Foo, scope: :class)

          var_desc               = table.variable_ids[:class]
          refute_empty           var_desc
          assert_equal 1, table.size_of(:static, scope: :class)

          assert_equal [:bar],   var_desc.keys
          assert_equal :static,  var_desc[:bar].kind
          assert_equal :Foo,     var_desc[:bar].type
        end
      end

      def test_variables_field
        SymbolTableTestHelper.with_new_table do |table|
          assert_empty           table.variable_ids

          table.register_variable(:foo, kind: :field, type: :integer, scope: :class)

          var_desc               = table.variable_ids[:class]
          refute_empty           var_desc
          assert_equal 1, table.size_of(:field, scope: :class)

          assert_equal [:foo],   var_desc.keys
          assert_equal :field,   var_desc[:foo].kind
          assert_equal :integer, var_desc[:foo].type
        end
      end

      def test_variables_local_for_method
        SymbolTableTestHelper.with_new_table do |table|
          table.register_subroutine(:foo_method, kind: :method, return_type: :void)

          var_desc                    = table.variable_ids[:foo_method]
          assert_equal 0, table.size_of(:local, scope: :foo_method)
          assert_equal [:this],       var_desc.keys

          table.register_variable(:foo, kind: :local, type: :boolean, scope: :foo_method)

          assert_equal 1, table.size_of(:local, scope: :foo_method)
          assert_equal [:this, :foo], var_desc.keys

          assert_equal :local,        var_desc[:foo].kind
          assert_equal :boolean,      var_desc[:foo].type
        end
      end

      def test_variables_argument_for_non_method
        SymbolTableTestHelper.with_new_table do |table|
          table.register_subroutine(:foo_func, kind: :function, return_type: :void)

          var_desc                    = table.variable_ids[:foo_func]
          assert_equal 0, table.size_of(:local, scope: :foo_func)
          assert_empty var_desc.keys

          table.register_variable(:foo, kind: :local, type: :boolean, scope: :foo_func)

          assert_equal 1, table.size_of(:local, scope: :foo_func)
          assert_equal [:foo], var_desc.keys

          assert_equal :local,        var_desc[:foo].kind
          assert_equal :boolean,      var_desc[:foo].type
        end
      end

      def test_variables_argument
        SymbolTableTestHelper.with_new_table do |table|
          table.register_subroutine(:foo_method, kind: :method, return_type: :void)

          var_desc                    = table.variable_ids[:foo_method]
          assert_equal [:this],       var_desc.keys

          table.register_variable(:foo, kind: :argument, type: :String, scope: :foo_method)
          assert_equal 2, table.size_of(:argument, scope: :foo_method)

          assert_equal [:this, :foo], var_desc.keys
          assert_equal :argument,     var_desc[:foo].kind
          assert_equal :String,       var_desc[:foo].type
        end
      end

      def test_register_duplicated_variables_under_the_same_scope
        SymbolTableTestHelper.with_new_table do |table|
          table.register_variable(:foobar, kind: :static, type: :Array, scope: :class)

          assert_raises(RuntimeError) {
            table.register_variable(:foobar, kind: :field, type: :boolean, scope: :class)
          }
        end

        SymbolTableTestHelper.with_new_table do |table|
          table.register_subroutine(:a_method, kind: :method, return_type: :void)
          table.register_variable(:foobar, kind: :argument, type: :String, scope: :a_method)

          assert_raises(RuntimeError) {
            table.register_variable(:foobar, kind: :local, type: :boolean, scope: :a_method)
          }
        end
      end

      def test_register_duplicated_variables_under_irrelevant_scopes
        SymbolTableTestHelper.with_new_table do |table|
          table.register_subroutine(:foo, kind: :method, return_type: :void)
          table.register_subroutine(:bar, kind: :method, return_type: :void)

          table.register_variable(:index, kind: :argument, type: :integer, scope: :foo)
          # won't raise anything
          table.register_variable(:index, kind: :local, type: :integer, scope: :bar)
        end
      end

      def test_register_duplicated_variables_under_overlapping_scopes
        SymbolTableTestHelper.with_new_table do |table|
          table.register_subroutine(:foo, kind: :method, return_type: :void)
          # NOTE: class-scoped variables are ALWAYS declared in advance to subroutine locals
          # (wrong ordered declaration lead to fail to detect variable shadowing, but that
          # has to be guranteed in other modules)
          table.register_variable(:total, kind: :field, type: :boolean, scope: :class)

          assert_raises(RuntimeError) {
            table.register_variable(:total, kind: :local, type: :integer, scope: :foo)
          }
        end
      end

      def test_lookup_subroutine
        SymbolTableTestHelper.with_new_table do |table|
          table.register_subroutine(:foo_method, kind: :method,      return_type: :String)
          table.register_subroutine(:bar_method, kind: :method,      return_type: :Array)
          table.register_subroutine(:foo_func,   kind: :function,    return_type: :void)
          table.register_subroutine(:bar_func,   kind: :function,    return_type: :boolean)
          table.register_subroutine(:new,        kind: :constructor, return_type: :integer)

          subroutine = table.lookup_subroutine(:foo_method)
          assert_equal :method, subroutine.kind
          assert_equal :String, subroutine.return_type

          subroutine = table.lookup_subroutine(:bar_method)
          assert_equal :method, subroutine.kind
          assert_equal :Array, subroutine.return_type

          subroutine = table.lookup_subroutine(:foo_func)
          assert_equal :function, subroutine.kind
          assert_equal :void, subroutine.return_type

          subroutine = table.lookup_subroutine(:bar_func)
          assert_equal :function, subroutine.kind
          assert_equal :boolean, subroutine.return_type

          subroutine = table.lookup_subroutine(:new)
          assert_equal :constructor, subroutine.kind
          assert_equal :integer, subroutine.return_type

          subroutine = table.lookup_subroutine(:non_existent)
          assert_nil subroutine
        end
      end

      def test_lookup_variables_in_class_scope
        SymbolTableTestHelper.with_new_table do |table|
          table.register_subroutine(:foo, kind: :method, return_type: :void)
          table.register_subroutine(:bar, kind: :method, return_type: :void)

          table.register_variable(:price,     kind: :field,    type: :integer, scope: :class)
          table.register_variable(:count,     kind: :field,    type: :integer, scope: :class)
          table.register_variable(:tax_rate,  kind: :static,   type: :Float,   scope: :class)
          table.register_variable(:surcharge, kind: :static,   type: :Float,   scope: :class)

          table.register_variable(:subtotal,  kind: :local,    type: :integer, scope: :foo)
          table.register_variable(:charge,    kind: :local,    type: :integer, scope: :foo)

          assert_nil table.lookup_variable(:subtotal,   scope: :class)
          assert_nil table.lookup_variable(:charge,     scope: :class)
          assert_nil table.lookup_variable(:this,       scope: :class)

          assert_equal 2, table.size_of(:static, scope: :class)
          assert_equal 2, table.size_of(:field,  scope: :class)
          price     = table.lookup_variable(:price,     scope: :class)
          count     = table.lookup_variable(:count,     scope: :class)
          tax_rate  = table.lookup_variable(:tax_rate,  scope: :class)
          surcharge = table.lookup_variable(:surcharge, scope: :class)

          assert_equal :field,   price.kind
          assert_equal :integer, price.type
          assert_equal 0,        price.number

          assert_equal :field,   count.kind
          assert_equal :integer, count.type
          assert_equal 1,        count.number

          assert_equal :static,  tax_rate.kind
          assert_equal :Float,   tax_rate.type
          assert_equal 0,        tax_rate.number

          assert_equal :static,  surcharge.kind
          assert_equal :Float,   surcharge.type
          assert_equal 1,        surcharge.number
        end
      end

      def test_lookup_variables_in_subroutine_scope
        SymbolTableTestHelper.with_new_table(class_name: :Payment) do |table|
          table.register_subroutine(:foo, kind: :method, return_type: :void)
          table.register_subroutine(:bar, kind: :method, return_type: :void)

          table.register_variable(:price,      kind: :field,    type: :integer, scope: :class)
          table.register_variable(:tax_rate,   kind: :static,   type: :Float,   scope: :class)

          table.register_variable(:count,      kind: :argument, type: :integer, scope: :foo)
          table.register_variable(:commission, kind: :argument, type: :Float,   scope: :foo)
          table.register_variable(:subtotal,   kind: :local,    type: :Float,   scope: :foo)

          table.register_variable(:count,      kind: :argument, type: :integer, scope: :bar)
          table.register_variable(:charge,     kind: :local,    type: :Float,   scope: :bar)

          assert_nil table.lookup_variable(:charge,       scope: :foo)

          assert_equal 3, table.size_of(:argument, scope: :foo)
          assert_equal 1, table.size_of(:local,    scope: :foo)
          price      = table.lookup_variable(:price,      scope: :foo)
          tax_rate   = table.lookup_variable(:tax_rate,   scope: :foo)
          this       = table.lookup_variable(:this,       scope: :foo)
          count      = table.lookup_variable(:count,      scope: :foo)
          commission = table.lookup_variable(:commission, scope: :foo)
          subtotal   = table.lookup_variable(:subtotal,   scope: :foo)

          assert_equal :field,    price.kind
          assert_equal :integer,  price.type
          assert_equal 0,         price.number

          assert_equal :static,   tax_rate.kind
          assert_equal :Float,    tax_rate.type
          assert_equal 0,         tax_rate.number

          assert_equal :argument, this.kind
          assert_equal :Payment,  this.type
          assert_equal 0,         this.number

          assert_equal :argument, count.kind
          assert_equal :integer,  count.type
          assert_equal 1,         count.number

          assert_equal :argument, commission.kind
          assert_equal :Float,    commission.type
          assert_equal 2,         commission.number

          assert_equal :local,    subtotal.kind
          assert_equal :Float,    subtotal.type
          assert_equal 0,         subtotal.number

          assert_nil table.lookup_variable(:commission, scope: :bar)
          assert_nil table.lookup_variable(:subtotal,   scope: :bar)

          price     = table.lookup_variable(:price,     scope: :bar)
          tax_rate  = table.lookup_variable(:tax_rate,  scope: :bar)
          this      = table.lookup_variable(:this,      scope: :bar)
          count     = table.lookup_variable(:count,     scope: :bar)
          charge    = table.lookup_variable(:charge,    scope: :bar)

          assert_equal :field,    price.kind
          assert_equal :integer,  price.type
          assert_equal 0,         price.number

          assert_equal :static,   tax_rate.kind
          assert_equal :Float,    tax_rate.type
          assert_equal 0,         tax_rate.number

          assert_equal :argument, this.kind
          assert_equal :Payment,  this.type
          assert_equal 0,         this.number

          assert_equal :argument, count.kind
          assert_equal :integer,  count.type
          assert_equal 1,         count.number

          assert_equal :local,    charge.kind
          assert_equal :Float,    charge.type
          assert_equal 0,         charge.number
        end
      end

      def test_lookup_variables_non_existent
        SymbolTableTestHelper.with_new_table do |table|
          table.register_subroutine(:foo, kind: :method, return_type: :void)
          table.register_subroutine(:bar, kind: :method, return_type: :void)

          table.register_variable(:count,    kind: :argument, type: :integer, scope: :foo)

          assert_nil table.lookup_variable(:count, scope: :foobarbaz)
          assert_nil table.lookup_variable(:count, scope: :bar)
          assert_nil table.lookup_variable(:count, scope: :class)
        end
      end
    end
  end
end
