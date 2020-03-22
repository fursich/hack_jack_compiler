require 'test_helper'

module JackCompiler
  module Parser
    class TestVisitorNodeTransformer < Minitest::Test
      class DummyFactory
        attr_reader :state, :children

        def initialize(node_type, kind: nil, value: nil)
          @state = {node_type: node_type, kind: kind, value: value}.compact
        end

        def build(*children)
          @children = children

          self
        end

        def kind
          @state[:kind]
        end

        def value
          @state[:value]
        end

        def aggregate
          children_states =
            if children.empty?
              {}
            else
              { children: children.map(&:aggregate) }
            end

          { state: state }.merge children_states
        end
      end

      def test_terminal
        node = VisitorTestHelper.build_terminal(:symbol, :+)

        factory = DummyFactory
        root = JackCompiler::Parser::NodeTransformer.new(factory).visit(node)
        expected_structure = {
          state: {
            node_type: :terminal,
            kind: :symbol,
            value: :'+'
          }
        }

        assert_equal expected_structure, root.aggregate
      end

      def test_variable_with_children
        node = VisitorTestHelper.build_variable(:class)
        VisitorTestHelper.append_child(node, category: :terminal, kind: :keyword,    value: :class)
        VisitorTestHelper.append_child(node, category: :terminal, kind: :identifier, value: :FooClass)
        VisitorTestHelper.append_child(node, category: :terminal, kind: :symbol,     value: :'{')

        factory = DummyFactory
        root = JackCompiler::Parser::NodeTransformer.new(factory).visit(node)
        expected_structure = {
          state: {
            node_type: :class,
          },
          children: [
            {
              state: {
                node_type: :terminal,
                kind: :keyword,
                value: :class
              }
            },
            {
              state: {
                node_type: :terminal,
                kind: :identifier,
                value: :FooClass
              }
            },
            {
              state: {
                node_type: :terminal,
                kind: :symbol,
                value: :'{'
              }
            }
          ]
        }

        assert_equal expected_structure, root.aggregate
      end
    end
  end
end
