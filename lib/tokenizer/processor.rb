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
            token = generate_token(code, last_type: token&.type, source_location: source.location).tap(&:validate!)

            @tokens << token unless token.ignorable?
            delete!(token.value, from: code)
          end
        end
      end

      private

      def delete!(element, from:)
        from.delete_prefix!(element.to_s)
      end

      def generate_token(raw_text, last_type:, source_location:)
        if last_type == :multiline_comment
          type, value = TokenClassifier.match_multiline_comment raw_text
        else
          type, value = TokenClassifier.match raw_text
        end

        Token.new(type, value, source_location: source_location)
      end
    end
  end
end
