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
            node.child(2).value,
            kind:        node.child(0).value,
            return_type: node.child(1).value,
          )
        elsif node.kind == :classVarDec
          kind     = node.child(0).value
          type     = node.child(1).value
          var_list = node.children[2..-1]
          var_list.each_slice(2) do |id, _sep|
            @symbol_table.register_variable(
              id.value,
              kind: kind,
              type: type,
              scope: :class,
            )
          end
        elsif node.kind == :varDec
          type     = node.child(1).value
          var_list = node.children[2..-1]
          var_list.each_slice(2) do |id, _sep|
            @symbol_table.register_variable(
              id.value,
              kind: :local,
              type: type,
              scope: node.scope,
            )
          end
        elsif node.kind == :parameterList
          var_list = node.children[0..-1]
          var_list.each_slice(2) do |type, id, _sep|
            @symbol_table.register_variable(
              id.value,
              kind: :argument,
              type: type.value,
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
