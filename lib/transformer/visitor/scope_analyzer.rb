module JackCompiler
  module Transformer
    class ScopeAnalyzer
      def visit(node)
        if node.kind == :subroutineDec
          node.scope = node.subroutine_name
        else
          node.scope = node.parent&.scope || :class
        end

        node.descendants.each do |child|
          child.accept(self)
        end

        node
      end
    end
  end
end
