module JackCompiler
  module Parser
    module Node
      class Base
        attr_reader :kind

        def initialize(kind)
          @kind = kind
        end
      end

      class Variable < Base
        extend Forwardable

        def_delegators :@children, :push, :pop
        attr_accessor :children

        def initialize(kind)
          super
          @children = []
        end

        def accept(visitor)
          visitor.visit_variable(self)
        end

        def child(i)
          children[i]
        end
      end

      class Terminal < Base
        attr_reader :value, :source_location

        def initialize(kind, value, source_location:)
          super(kind)
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
