module JackCompiler
  module Transformer
    class NodeExtractor
      def visit(node)
        node.extract_nodes!
        node.descendants.each do |sub_node|
          sub_node.accept(self)
        end

        node
      end
    end
  end
end
