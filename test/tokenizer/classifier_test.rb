require 'test_helper'

module JackCompiler
  module Tokenizer
    module TokenClassifierTestHelper
      def self.match(token, &block)
        token_kind, value = JackCompiler::Tokenizer::TokenClassifier.match(token)
        block.call token_kind, value
      end

      def self.match_multiline_comment(token, &block)
        token_kind, value = JackCompiler::Tokenizer::TokenClassifier.match_multiline_comment(token)
        block.call token_kind, value
      end
    end
  
    class TestTokenizerClassifier < Minitest::Test
      def test_blank_command
        TokenClassifierTestHelper.match(
          "   ",
        ) do |kind, value|
          assert_equal :space, kind
          assert_equal "   ", value
        end
      end
  
      def test_singleline_comment
        TokenClassifierTestHelper.match(
          "// one-liner comment",
        ) do |kind, value|
          assert_equal :singleline_comment, kind
          assert_equal "// one-liner comment", value
        end
      end

      def test_multiline_comment
        comments = [
          '/* comments starts here',
          '',
          'blah blah',
          '/* blah * //blah/ **blah',
          '...',
          '(コメント)',
          'ends here */ let xxx = 1',
        ]

        TokenClassifierTestHelper.match(
          comments[0]
        ) do |kind, value|
          assert_equal :multiline_comment, kind
          assert_equal '/*', value
        end

        1.upto(comments.size-2) do |i|
          TokenClassifierTestHelper.match_multiline_comment(
            comments[i]
          ) do |kind, value|
            assert_equal :multiline_comment, kind
            assert_equal comments[i], value
          end
        end

        TokenClassifierTestHelper.match_multiline_comment(
          comments[-1]
        ) do |kind, value|
          assert_equal :multiline_comment_closer, kind
          assert_equal 'ends here */', value
        end
      end
  
      def test_undefined_token_kinds
        tokens = %w[classFoo function#bar 1st_var "abc xyz" "foo"123 Foo@rb bar$baz αβ \10000 #]
        tokens.each do |token|
        TokenClassifierTestHelper.match(
            token,
          ) do |kind, value|
            assert_equal :undefined, kind
            assert_nil value
          end
        end
      end
  
      def test_keywords
        keywords = %w[class constructor function method field static var int char boolean void true false null this let do if else while return]
        keywords.each do |keyword|
        TokenClassifierTestHelper.match(
            "#{keyword} something",
          ) do |kind, value|
            assert_equal :keyword, kind
            assert_equal keyword.to_sym, value
          end
        end
      end
  
      def test_symbol
        symbols = %w[{ } ( ) [ ] . , ; + - * / & | < > = ~]
        symbols.each do |symbol|
        TokenClassifierTestHelper.match(
            "#{symbol}with-other-strings",
          ) do |kind, value|
            assert_equal :symbol, kind
            assert_equal symbol.to_sym, value
          end
        end
      end
  
      def test_identifiers
        identifiers = %w[foo bar_baz FooBar_BAZ]
        identifiers.each do |identifier|
        TokenClassifierTestHelper.match(
            "#{identifier}(foo)\n",
          ) do |kind, value|
            assert_equal :identifier, kind
            assert_equal identifier.to_sym, value
          end
        end
      end
  
      def test_integers
        integers = %w[1 123 8888888]
        integers.each do |integer|
        TokenClassifierTestHelper.match(
            "#{integer}*foo+bar",
          ) do |kind, value|
            assert_equal :integer, kind
            assert_equal integer.to_i, value
          end
        end
      end
  
      def test_strings
        strings = %w["foo" "bar\ baz" "日本語による、文字表記や　文章・パラグラフ"]
        strings.each do |string|
        TokenClassifierTestHelper.match(
            "#{string},  abc, def",
          ) do |kind, value|
            assert_equal :string, kind
            assert_equal string.to_s, value
          end
        end
      end
    end
  end
end
