require 'test_helper'

module JackCompiler
  module Parser
    module TokenClassifierTestHelper
      def self.match(token, &block)
        token_type = JackCompiler::Parser::TokenClassifier.match(token)
        block.call token_type
      end
    end
  
    class TestTokenizerClassifier < Minitest::Test
      def test_blank_command
        TokenClassifierTestHelper.match(
          "   ",
        ) do |type|
          assert_nil type
        end
      end
  
      def test_comments
        TokenClassifierTestHelper.match(
          " // comment",
        ) do |type|
          assert_nil type
        end
      end
  
      def test_undefined_token_types
        tokens = %w[0foo "abc xyz" Foo.rb bar$baz αβ -10000 # \ ()]
        tokens.each do |token|
        TokenClassifierTestHelper.match(
            token,
          ) do |type|
            assert_nil type
          end
        end
      end
  
      def test_keywords
        keywords = %w[class constructor function method field static var int char boolean void true false null this let do if else while return]
        keywords.each do |keyword|
        TokenClassifierTestHelper.match(
            keyword,
          ) do |type|
            assert_equal :keyword, type
          end
        end
      end
  
      def test_symbol
        symbols = %w[{ } ( ) [ ] . , ; + - * / & | < > = ~]
        symbols.each do |symbol|
        TokenClassifierTestHelper.match(
            symbol,
          ) do |type|
            assert_equal :symbol, type
          end
        end
      end
  
      def test_identifiers
        identifiers = %w[foo bar_baz FooBar_BAZ]
        identifiers.each do |identifier|
        TokenClassifierTestHelper.match(
            identifier,
          ) do |type|
            assert_equal :identifier, type
          end
        end
      end
  
      def test_integers
        integers = %w[1 123 8888888]
        integers.each do |integer|
        TokenClassifierTestHelper.match(
            integer,
          ) do |type|
            assert_equal :int_const, type
          end
        end
      end
  
      def test_strings
        strings = %w["foo" "bar\ baz" "日本語による、文字表記や　文章・パラグラフ"]
        strings.each do |string|
        TokenClassifierTestHelper.match(
            string,
          ) do |type|
            assert_equal :string_const, type
          end
        end
      end
    end
  end
end
