module JackCompiler
  module Transformer
    class NodeFactory
      include Inflector

      attr_reader :node_type, :kind, :value

      def initialize(node_type, kind: nil, value: nil)
        @kind      = kind || node_type
        @value     = value
        @node_type =
          if node_type == :class
            :klass
          else
            node_type
          end
      end

      def build(*children)
        node_class = constantize(node_type, base: JackCompiler::Transformer::Node)
        node = node_class.new(kind, *children)

        if node_type == :terminal
          node.value = value
        end

        node
      end
    end
  end
end
