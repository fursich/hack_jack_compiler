module JackCompiler
  module Parser
    module SymbolDeclairator
      class << self
        def initialize(symbol_table)
          @symbol_table = symbol_table
        end

        def visit(root)
          root.accept self
        end

        def visit_variable(node)
          if node.type == :subroutineDec
            @symbol_table.register_subroutine(
              node.child(2),
              kind:        node.child(0).value,
              return_type: node.child(1).value,
            )
          elsif node.type == :classVarDec
            kind     = node.child(0)
            type     = node.child(1)
            var_list = node.children[2..-1]
            var_list.each_slice(2) do |id, _sep|
              @symbol_table.register_variable(
                id,
                kind: kind,
                type: type,
                scope: :class,
              )
            end
          elsif node.type == :varDec
            type     = node.child(1)
            var_list = node.children[2..-1]
            var_list.each_slice(2) do |id, _sep|
              @symbol_table.register_variable(
                id,
                kind: :local,
                type: type,
                scope: node.scope,
              )
            end
          elsif node.type == :parameterList
            type     = node.child(0)
            var_list = node.children[1..-1]
            var_list.each_slice(2) do |id, _sep|
              @symbol_table.register_variable(
                id,
                kind: :argument,
                type: type,
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
end
