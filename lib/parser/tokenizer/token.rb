module JackCompiler
  module Parser
    class Token
      attr_reader :token, :type, :source_location
  
      def initialize(token, source_location:)
        @token           = token
        @source_location = source_location
      end
  
      def classify!
        @type = TokenClassifier.match @token
        raise UndefinedTokenPattern, "undefined token pattern found: #{source_location}" unless @type
        self
      end
    end
  end
end
