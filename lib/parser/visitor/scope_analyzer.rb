module JackCompiler
  module Parser
    module ScopeAnalyzer
      class << self
        def visit(root)
          root.accept self
        end

        def visit_variable(node)
          if node.kind == :subroutineDec
            node.scope = node.child(2).value
          else
            node.scope = node.parent&.scope || :class
          end

          node.children.each do |child|
            child.accept(self)
          end
        end

        def visit_terminal(node)
          node.scope = node.parent&.scope || :class
        end
      end
    end
  end
end
