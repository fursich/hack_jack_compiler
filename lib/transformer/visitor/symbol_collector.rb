module JackCompiler
  module Transformer
    class SymbolCollector
      def initialize(symbol_table)
        @symbol_table = symbol_table
      end

      def visit(node)
        if node.kind == :class
          @symbol_table.register_class(
            node.class_name
          )
        elsif node.kind == :subroutineDec
          @symbol_table.register_subroutine(
            node.subroutine_name,
            kind:        node.subroutine_kind,
            return_type: node.return_type,
          )
        elsif node.kind == :classVarDec
          kind      = node.var_kind
          type      = node.type
          var_names = node.var_names
          var_names.each do |name|
            @symbol_table.register_variable(
              name,
              kind: kind,
              type: type,
              scope: :class,
            )
          end
        elsif node.kind == :varDec
          type      = node.type
          var_names = node.var_names
          var_names.each do |name|
            @symbol_table.register_variable(
              name,
              kind: :local,
              type: type,
              scope: node.scope,
            )
          end
        elsif node.kind == :parameterList
          parameters = node.parameters
          parameters.each do |var_name, type|
            @symbol_table.register_variable(
              var_name,
              kind: :argument,
              type: type,
              scope: node.scope,
            )
          end
        end

        node.descendants.each do |sub_node|
          sub_node.accept(self)
        end

        node
      end
    end
  end
end
