module JackCompiler
  module Parser
    module ParentConnector
      class << self
        def visit(root)
          root.accept self
        end

        def visit_variable(node)
          node.children.each do |child|
            child.parent = node
            child.accept(self)
          end
        end

        def visit_terminal(node)
          # nop
        end
      end
    end
  end
end