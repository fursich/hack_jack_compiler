module JackCompiler
  module Transformer
    module VisitorTestHelper
      class << self
        include Inflector

        def build_node(*children, kind:, value: nil)
          factory = JackCompiler::Transformer::NodeFactory.new(kind, kind: kind, value: value)
          factory.build(*children)
        end

        def append_child(node, category: :variable, kind: :term, value: nil)
          child =
            if category == :terminal
              build_node(kind: :terminal, value: value)
            else
              build_node(kind: kind, value: value)
            end

          node.children.push child
          child
        end

        def append_children(node, count, category: :variable, kind: :term, value: nil)
          count.times do
            append_child(node, category: category, kind: kind, value: value)
          end
        end

        def build_descendants(node, count:, depth:, kind:, value:)
          if depth > 1
            append_children(node, count, category: :variable, kind: kind)
          elsif depth == 1
            append_children(node, count, category: :terminal, kind: :identifier, value: value)
            return
          else
            raise RuntimeError, 'depth: must be greater than 0'
          end

          node.children.each do |child|
            build_descendants(child, count: count, depth: depth-1, kind: kind, value: value)
          end
        end

        def prepare_class(class_name)
          root = build_node(kind: :class)
          append_child(root, category: :terminal, kind: :keyword,    value: :class)
          append_child(root, category: :terminal, kind: :identifier, value: class_name)
          append_child(root, category: :terminal, kind: :symbol,     value: :'{')

          root
        end

        def prepare_class_var_dec(kind, type, *vars)
          body = build_node(kind: :classVarDec)
          append_child(body, category: :terminal, kind: :keyword, value: kind)
          append_child(body, category: :terminal, kind: :keyword, value: type)

          vars.each do |name|
            append_child(body, category: :terminal, kind: :identifier, value: name)
            if name == vars.last
              append_child(body, category: :terminal, kind: :symbol, value: :';')
            else
              append_child(body, category: :terminal, kind: :symbol, value: :',')
            end
          end

          body
        end

        def prepare_subroutine(name, kind, return_type=:void, **vars)
          sub = build_node(kind: :subroutineDec)
          append_child(sub, category: :terminal, kind: :keyword, value: kind)
          append_child(sub, category: :terminal, kind: :keyword, value: return_type)
          append_child(sub, category: :terminal, kind: :identifier, value: name)
          append_child(sub, category: :terminal, kind: :symbol, value: :'(')

          list = append_child(sub, category: :variable, kind: :parameterList)
          vars.each do |name, type|
            append_child(list, category: :terminal, kind: :keyword, value: type)
            append_child(list, category: :terminal, kind: :identifier, value: name)
          end

          append_child(sub, category: :terminal, kind: :symbol, value: :')')
          append_child(sub, category: :variable, kind: :subroutineBody)

          sub
        end

        def prepare_var_dec(type, *vars)
          body = build_node(kind: :varDec)
          append_child(body, category: :terminal, kind: :keyword, value: :var)
          append_child(body, category: :terminal, kind: :keyword, value: type)

          vars.each do |name|
            append_child(body, category: :terminal, kind: :identifier, value: name)
            if name == vars.last
              append_child(body, category: :terminal, kind: :symbol, value: :';')
            else
              append_child(body, category: :terminal, kind: :symbol, value: :',')
            end
          end

          body
        end
      end

      def self.prepare_simple_exp(kind, value)
        exp = build_node(kind: :expression)
        append_child(exp, category: :terminal, kind: kind, value: value)
        exp
      end

      def self.prepare_parser(raw_source, filename: 'filename.jack')
        source    = JackCompiler::Source.new(filename).tap { |source| source.store!(raw_source) }
        tokenizer = JackCompiler::Tokenizer::Processor.new(source).tap(&:tokenize!)
        JackCompiler::Parser::Processor.new(tokenizer.tokens)
      end

      def self.prepare_tree(raw_source, root_node:, filename: 'filename.jack')
        parser = prepare_parser(raw_source, filename: filename)
        parser.send "parse_#{root_node}"
      end

      class DummyFactory
        attr_reader :node_type, :state
        def initialize(kind)
          @node_type = kind
        end

        def build(*children, kind: nil, value: nil)
          @state = {children: children, kind: kind, value: value}.compact

          self
        end

        def children
          @state[:children]
        end

        def kind
          @state[:kind]
        end

        def value
          @state[:value]
        end

        def states
          { node_type: node_type,
            children: children.empty? ? nil: children,
            kind: kind,
            value: value
          }.compact
        end

        def aggregate
          { states: states.slice(:node_type, :kind, :value),
            children: children.empty? ? nil: childre.map { |child|
              child.aggregate
            }
          }.compact
        end
      end
    end
  end
end
