module JackCompiler
  module Tokenizer
    class Token
      MAX_INT = 32767
      MIN_INT = 0
      attr_reader :type, :value, :source_location

      def initialize(type, value, source_location:)
        @type            = type
        @value           = value
        @source_location = source_location
      end

      def validate!
        raise UndefinedTokenPattern, "undefined token pattern found: #{source_location}" unless valid_type?
        raise IllegalIntegerValue,   "integer value #{value} is out of acceptable range (#{MIN_INT}-#{MAX_INT})" unless valid_as_integer?

        true
      end

      def keyword?
        @type == :keyword
      end

      def symbol?
        @type == :symbol
      end

      def identifier?
        @type == :identifier
      end

      def integer?
        @type == :integer
      end

      def string?
        @type == :string
      end

      def comment?
        @type == :singleline_comment || @type == :multiline_comment || @type == :multiline_comment_closer
      end

      def space?
        @type == :space
      end

      def ignorable?
        space? || comment?
      end

      def is?(token_type)
        element.to_sym == token_type.to_s.to_sym
      end

      def to_s
        type_str = sprintf("%-11s", type.upcase)
        value_str = sprintf("%-15.15s", "#{value}") + (value.size > 15 ? '..' : '  ')

        "type: #{type_str} value: #{value_str} : #{source_location}"
      end

      private

      def element
        if keyword? || symbol?
          value
        else
          type
        end
      end

      def valid_type?
        keyword? || symbol? || identifier? || integer? || string? || comment? || space?
      end

      def valid_as_integer?
        return true unless integer?

        value.between? MIN_INT, MAX_INT
      end
    end
  end
end
