module JackCompiler
  module Parser
    module Node
      class Base
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

        def to_xml
          ["<#{type}>", *children.flat_map(&:to_xml).map { |child| "  #{child}" }, "</#{type}>"]
        end

        def prettify
          ["└ #{type}", *children.flat_map(&:prettify).map { |child| "     #{child}" } ]
        end
      end

      class Terminal < Base
        attr_reader :type, :value, :source_location

        def initialize(type, value, source_location:)
          super(type)
          @value           = value
          @source_location = source_location
        end

        def to_xml
          "<#{type}> #{value} </#{type}>"
        end

        def prettify
          "└ *#{type} <#{value}>"
        end
      end
    end
  end
end
