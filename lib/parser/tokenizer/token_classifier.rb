module JackCompiler
  module Parser
    module TokenClassifier
      KeywordMatcher    = /\A(class|constructor|function|method|field|static|var|int|char|boolean|void|true|false|null|this|let|do|if|else|while|return)\z/
      SymbolMatcher     = /\A[{}()\[\].,;+\-*\/&|<>=~]\z/
      IdentifierMatcher = /\A[a-zA-Z_][0-9a-zA-Z_]*\z/
      IntegerMatcher    = /\A[0-9]+\z/
      StringMatcher     = /\A"[^"\n]*"\z/
  
      def self.match(token)
        case token
        when KeywordMatcher
          :keyword
        when SymbolMatcher
          :symbol
        when IdentifierMatcher
          :identifier
        when IntegerMatcher
          :int_const
        when StringMatcher
          :string_const
        else
          nil
        end
      end
    end
  end
end
