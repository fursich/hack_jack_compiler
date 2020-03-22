module JackCompiler
  module Transformer
    class SimpleFormatter
      def visit(node)
        [
          "#{node.class.name.split('::').last}: #{node.kind} | parent #{node.parent&.kind || '<NO PARENT>'}",
          *node.descendants.flat_map { |child| child.accept(self) }.map { |format| "  " + format }
        ]
      end
    end
  end
end
