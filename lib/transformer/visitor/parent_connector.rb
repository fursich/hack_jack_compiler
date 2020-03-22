module JackCompiler
  module Transformer
    class ParentConnector
      def visit(node)
        node.descendants.each do |child|
          child.parent = node
          child.accept(self)
        end

        node
      end
    end
  end
end
