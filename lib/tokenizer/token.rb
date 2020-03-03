module JackCompiler
  module Tokenizer
    class Token
      MAX_INT = 32767
      MIN_INT = 0
      attr_reader :kind, :value, :source_location

      def initialize(kind, value, source_location:)
        @kind            = kind
        @value           = value
        @source_location = source_location
      end

      def validate!
        raise UndefinedTokenPattern, "undefined token pattern found: #{source_location}" unless valid_kind?
        raise IllegalIntegerValue,   "integer value #{value} is out of acceptable range (#{MIN_INT}-#{MAX_INT})" unless valid_as_integer?

        true
      end

      def keyword?
        @kind == :keyword
      end

      def symbol?
        @kind == :symbol
      end

      def identifier?
        @kind == :identifier
      end

      def integer?
        @kind == :integer
      end

      def string?
        @kind == :string
      end

      def comment?
        @kind == :singleline_comment || @kind == :multiline_comment || @kind == :multiline_comment_closer
      end

      def space?
        @kind == :space
      end

      def ignorable?
        space? || comment?
      end

      def is?(token_kind)
        element.to_sym == token_kind.to_s.to_sym
      end

      def to_s
        kind_str = sprintf("%-11s", kind.upcase)
        value_str = sprintf("%-15.15s", "#{value}") + (value.size > 15 ? '..' : '  ')

        "kind: #{kind_str} value: #{value_str} : #{source_location}"
      end

      private

      def element
        if keyword? || symbol?
          value
        else
          kind
        end
      end

      def valid_kind?
        keyword? || symbol? || identifier? || integer? || string? || comment? || space?
      end

      def valid_as_integer?
        return true unless integer?

        value.between? MIN_INT, MAX_INT
      end
    end
  end
end
