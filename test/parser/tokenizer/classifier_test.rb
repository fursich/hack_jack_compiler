require 'test_helper'

module JackCompiler
  module Parser
    module TokenClassifierTestHelper
      def self.match(token, &block)
        token_type, value = JackCompiler::Parser::TokenClassifier.match(token)
        block.call token_type, value
      end

      def self.match_multiline_comment(token, &block)
        token_type, value = JackCompiler::Parser::TokenClassifier.match_multiline_comment(token)
        block.call token_type, value
      end
    end
  
    class TestTokenizerClassifier < Minitest::Test
      def test_blank_command
        TokenClassifierTestHelper.match(
          "   ",
        ) do |type, value|
          assert_equal :space, type
          assert_equal "   ", value
        end
      end
  
      def test_singleline_comment
        TokenClassifierTestHelper.match(
          "// one-liner comment",
        ) do |type, value|
          assert_equal :singleline_comment, type
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
        ) do |type, value|
          assert_equal :multiline_comment, type
          assert_equal '/*', value
        end

        1.upto(comments.size-2) do |i|
          TokenClassifierTestHelper.match_multiline_comment(
            comments[i]
          ) do |type, value|
            assert_equal :multiline_comment, type
            assert_equal comments[i], value
          end
        end

        TokenClassifierTestHelper.match_multiline_comment(
          comments[-1]
        ) do |type, value|
          assert_equal :multiline_comment_closer, type
          assert_equal 'ends here */', value
        end
      end
  
      def test_undefined_token_types
        tokens = %w[classFoo function#bar 1st_var "abc xyz" "foo"123 Foo@rb bar$baz αβ \10000 #]
        tokens.each do |token|
        TokenClassifierTestHelper.match(
            token,
          ) do |type, value|
            assert_equal :undefined, type
            assert_nil value
          end
        end
      end
  
      def test_keywords
        keywords = %w[class constructor function method field static var int char boolean void true false null this let do if else while return]
        keywords.each do |keyword|
        TokenClassifierTestHelper.match(
            "#{keyword} something",
          ) do |type, value|
            assert_equal :keyword, type
            assert_equal keyword.to_sym, value
          end
        end
      end
  
      def test_symbol
        symbols = %w[{ } ( ) [ ] . , ; + - * / & | < > = ~]
        symbols.each do |symbol|
        TokenClassifierTestHelper.match(
            "#{symbol}with-other-strings",
          ) do |type, value|
            assert_equal :symbol, type
            assert_equal symbol.to_sym, value
          end
        end
      end
  
      def test_identifiers
        identifiers = %w[foo bar_baz FooBar_BAZ]
        identifiers.each do |identifier|
        TokenClassifierTestHelper.match(
            "#{identifier}(foo)\n",
          ) do |type, value|
            assert_equal :identifier, type
            assert_equal identifier.to_sym, value
          end
        end
      end
  
      def test_integers
        integers = %w[1 123 8888888]
        integers.each do |integer|
        TokenClassifierTestHelper.match(
            "#{integer}*foo+bar",
          ) do |type, value|
            assert_equal :integer, type
            assert_equal integer.to_i, value
          end
        end
      end
  
      def test_strings
        strings = %w["foo" "bar\ baz" "日本語による、文字表記や　文章・パラグラフ"]
        strings.each do |string|
        TokenClassifierTestHelper.match(
            "#{string},  abc, def",
          ) do |type, value|
            assert_equal :string, type
            assert_equal string.to_s, value
          end
        end
      end
    end
  end
end
