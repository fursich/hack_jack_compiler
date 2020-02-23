module JackCompiler
  module Parser
    class TokenContainer
      attr_reader :tokens, :size

      def initialize(tokens)
        @tokens = tokens
        @size   = tokens.size
        @cursor = 0
      end

      def current_token
        peep(0)
      end

      def next_token
        peep(1)
      end

      def pop
        token = current_token
        @cursor += 1
        token
      end

      def peep(offset)
        tokens[@cursor + offset] if (@cursor + offset).between?(0, size)
      end
    end
  end
end
