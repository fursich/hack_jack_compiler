module JackCompiler
  module Tokenizer
    module TokenClassifier
      Keyword                       = /(class|constructor|function|method|field|static|var|int|char|boolean|void|true|false|null|this|let|do|if|else|while|return)/
      Symbol                        = /[{}()\[\].,;+\-*\/&|<>=~]/
      Identifier                    = /[a-zA-Z_][0-9a-zA-Z_]*/
      Integer                       = /[0-9]+/
      String                        = /"[^"\n\r]*"/
      Spaces                        = /\s+/
      Separator                     = Regexp.union(Spaces, Symbol)

      KeywordMatcher                = /\A#{Keyword}(?=#{Separator})/
      SymbolMatcher                 = /\A#{Symbol}/
      IdentifierMatcher             = /\A#{Identifier}(?=#{Separator})/
      IntegerMatcher                = /\A#{Integer}(?=#{Separator})/
      StringMatcher                 = /\A#{String}(?=#{Separator})/
      SpacesMatcher                 = /\A#{Spaces}/

      SingleLineCommentMatcher      = /\A\/\/.*\z/
      MultiLineCommentOpenerMatcher = /\A\/\*/
      MultiLineCommentCloser        = /\*\//
      MultiLineCommentCloserMatcher = /\A.*?#{MultiLineCommentCloser}/
  
      def self.match(text)
        case text
        when SpacesMatcher
          [:space,                    $&.to_s]
        when SingleLineCommentMatcher
          [:singleline_comment,       $&.to_s]
        when MultiLineCommentOpenerMatcher
          [:multiline_comment,        $&.to_s]

        when KeywordMatcher
          # requred to judge earlier than identifier to match correctly
          [:keyword,                  $&.to_sym]
        when SymbolMatcher
          [:symbol,                   $&.to_sym]
        when IdentifierMatcher
          [:identifier,               $&.to_sym]
        when IntegerMatcher
          [:integer,                  Integer($&)]
        when StringMatcher
          [:string,                   $&.to_s]

        else
          [:undefined,                nil]
        end
      end

      def self.match_multiline_comment(text)
        if text.match MultiLineCommentCloserMatcher
          [:multiline_comment_closer, $&.to_s]
        else
          [:multiline_comment,        text.to_s]
        end
      end
    end
  end
end
