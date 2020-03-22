module JackCompiler
  module Transformer
    module Node
      class Base
#        extend Forwardable
#        def_delegators :@children, :slice!

        attr_accessor :parent, :scope
        attr_accessor :children
        attr_reader   :kind

        def initialize(kind, *children)
          @children = children
          @kind     = kind
        end

        def descendants
          []
        end

        def accept(visitor)
          visitor.visit(self)
        end

        def child(i)
          children[i]
        end

        def extract_children(index, kind:)
          kinds = Array(kind)
          children[index..-1].select { |child|
            kinds.include? child.kind
          }
        end
      end
    end
  end
end
