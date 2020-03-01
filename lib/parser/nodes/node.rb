module JackCompiler
  module Parser
    module Node
      class Base
        attr_accessor :parent

        def initialize(type)
          @type = type
        end
      end

      class Variable < Base
        extend Forwardable

        def_delegators :@children, :push, :pop
        attr_accessor :children
        attr_reader :type

        def initialize(type)
          super
          @children = []
        end

        def accept(visitor)
          visitor.visit_variable(self)
        end
      end

      class Terminal < Base
        attr_reader :type, :value, :source_location

        def initialize(type, value, source_location:)
          super(type)
          @value           = value
          @source_location = source_location
        end

        def accept(visitor)
          visitor.visit_terminal(self)
        end
      end
    end
  end
end
