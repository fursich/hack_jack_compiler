module JackCompiler
  module Parser
    class SymbolDeclairator
      def initialize(symbol_table)
        @symbol_table = symbol_table
      end

      def visit(root)
        root.accept self
      end

      def visit_variable(node)
        if node.kind == :subroutineDec
          @symbol_table.register_subroutine(
            node.child(2),
            kind:        node.child(0).value,
            return_type: node.child(1).value,
          )
        elsif node.kind == :classVarDec
          kind     = node.child(0)
          kind     = node.child(1)
          var_list = node.children[2..-1]
          var_list.each_slice(2) do |id, _sep|
            @symbol_table.register_variable(
              id,
              kind: kind,
              kind: kind,
              scope: :class,
            )
          end
        elsif node.kind == :varDec
          kind     = node.child(1)
          var_list = node.children[2..-1]
          var_list.each_slice(2) do |id, _sep|
            @symbol_table.register_variable(
              id,
              kind: :local,
              kind: kind,
              scope: node.scope,
            )
          end
        elsif node.kind == :parameterList
          kind     = node.child(0)
          var_list = node.children[1..-1]
          var_list.each_slice(2) do |id, _sep|
            @symbol_table.register_variable(
              id,
              kind: :argument,
              kind: kind,
              scope: node.scope,
            )
          end
        end

        node.children.each do |child|
          child.accept(self)
        end
      end

      def visit_terminal(node)
        # nop
      end
    end
  end
end
