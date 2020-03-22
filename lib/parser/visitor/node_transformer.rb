module JackCompiler
  module Parser
    class NodeTransformer
      def initialize(factory)
        @factory = factory
      end

      def visit(root)
        root.accept(self)
      end

      def visit_variable(node)
        @factory.new(node.kind).build(
          *node.children.map { |child|
            child.accept(self)
          }
        )
      end

      def visit_terminal(node)
        @factory.new(:terminal, kind: node.kind, value: node.value).build
      end
    end
  end
end
