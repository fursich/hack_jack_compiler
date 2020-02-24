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

        def to_s
          "Variable Node: #{type}, children: [#{children.flat_map(&:type).join(%[, ])}]"
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
          "<#{type_for_xml}> #{value_for_xml} </#{type_for_xml}>"
        end

        def prettify
          "└ *#{type} <#{value}>"
        end

        def to_s
          "Terminal Node: #{type} <#{value}>"
        end

        private

        def value_for_xml
          if type == :string
            value.to_s.gsub(/\A"(.+)"\z/, '\1').encode(xml: :text)
          else
            value.to_s.encode(xml: :text)
          end
        end

        def type_for_xml
          case type
          when :string
            :stringConstant
          when :integer
            :integerConstant
          else
            type
          end
        end
      end
    end
  end
end
