require_relative 'token'
require_relative 'token_classifier'

module JackCompiler
  module Tokenizer
    class Processor
      attr_reader :tokens, :source

      def initialize(source)
        @source = source
        @tokens = []
      end
  
      def tokenize!
        token = nil
        while code = source.pop
          while !code.empty?
            token = generate_token(code, last_kind: token&.kind, source_location: source.location).tap(&:validate!)

            @tokens << token unless token.ignorable?
            delete!(token, from: code)
          end
        end
      end

      def print
        puts @tokens.map(&:to_s).join("\n")
      end

      private

      def delete!(token, from:)
        element =
          if token.kind == :string
            "\"#{token.value}\"" # for string, \" should be included in both ends
          else
            token.value.to_s
          end

        raise UndefinedTokenPattern, "(Internal Error) failed to tokenize #{from} : #{source.location}" unless from.start_with? element
        from.delete_prefix!(element)
      end

      def generate_token(raw_text, last_kind:, source_location:)
        if last_kind == :multiline_comment
          kind, value = TokenClassifier.match_multiline_comment raw_text
        else
          kind, value = TokenClassifier.match raw_text
        end

        Token.new(kind, value, source_location: source_location)
      end
    end
  end
end
