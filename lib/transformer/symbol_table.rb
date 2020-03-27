module JackCompiler
  module Transformer
    class SymbolTable
      RoutineDesc  = Struct.new(:kind, :return_type,   keyword_init: true)
      VariableDesc = Struct.new(:kind, :type, :number, keyword_init: true)

      attr_reader   :class_name, :subroutine_ids, :variable_ids

      def initialize
        @class_name     = :Klass # default
        @subroutine_ids = {}
        @variable_ids   = {}
      end

      def register_class(identifier)
        @class_name = identifier
      end

      def register_subroutine(identifier, kind:, return_type:)
        raise if subroutine_ids.has_key?(identifier)

        subroutine_ids[identifier] = RoutineDesc.new(kind: kind, return_type: return_type)
        register_variable(:this, kind: :argument, type: class_name, scope: identifier)
      end

      def register_variable(identifier, kind:, type:, scope:)
        raise if lookup_variable(identifier, scope: scope)

        variable_ids[scope] ||= {}
        variable_ids[scope][identifier] =
          VariableDesc.new(
            kind: kind,
            type: type,
            number: size_of(kind, scope: scope)
          )
      end

      def lookup_variable(identifier, scope:)
        class_var = lookup_scoped_variable(identifier, scope: :class)
        return class_var if class_var

        lookup_scoped_variable(identifier, scope: scope)
      end

      def size_of(kind, scope:)
        raise unless variable_ids.has_key?(scope)

        variable_ids[scope].count { |_id, var| var.kind == kind }
      end

      private

      def lookup_scoped_variable(identifier, scope:)
        return unless variable_ids.has_key?(scope)

        variable_ids[scope][identifier]
      end
    end
  end
end
