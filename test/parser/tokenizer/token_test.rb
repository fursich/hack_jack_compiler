require 'test_helper'

module JackCompiler
  module Parser
    module TokenTestHelper
      def self.token(token, source_location: "123", &block)
        token = JackCompiler::Parser::Token.new(token, source_location: source_location)

        block.call token
      end

      def self.classify!(token, source_location: "123", &block)
        token = JackCompiler::Parser::Token.new(token, source_location: source_location)
        token.classify!

        block.call token
      end
    end
  
    class TestTokenizerToken < Minitest::Test
      def test_blank_command
        TokenTestHelper.token(
          "   ",
        ) do |token|
          assert_raises(JackCompiler::Parser::UndefinedTokenPattern) { token.classify! }
        end
      end
  
      def test_comments
        TokenTestHelper.token(
          " // comment",
        ) do |token|
          assert_raises(JackCompiler::Parser::UndefinedTokenPattern) { token.classify! }
        end
      end
  
      def test_undefined_token_types
        tokens = %w[0foo "abc xyz" Foo.rb bar$baz αβ -10000 # \ ()]
        tokens.each do |token|
        TokenTestHelper.token(
            token,
          ) do |token|
            assert_raises(JackCompiler::Parser::UndefinedTokenPattern) { token.classify! }
          end
        end
      end
  
      def test_keywords
        keywords = %w[class constructor function method field static var int char boolean void true false null this let do if else while return]
        keywords.each do |keyword|
        TokenTestHelper.classify!(
            keyword,
          ) do |token|
            assert_equal :keyword, token.type
          end
        end
      end
  
      def test_symbol
        symbols = %w[{ } ( ) [ ] . , ; + - * / & | < > = ~]
        symbols.each do |symbol|
        TokenTestHelper.classify!(
            symbol,
          ) do |token|
            assert_equal :symbol, token.type
          end
        end
      end
  
      def test_identifiers
        identifiers = %w[foo bar_baz FooBar_BAZ]
        identifiers.each do |identifier|
        TokenTestHelper.classify!(
            identifier,
          ) do |token|
            assert_equal :identifier, token.type
          end
        end
      end
  
      def test_integers
        integers = %w[1 123 8888888]
        integers.each do |integer|
        TokenTestHelper.classify!(
            integer,
          ) do |token|
            assert_equal :int_const, token.type
          end
        end
      end
  
      def test_strings
        strings = %w["foo" "bar\ baz" "日本語による、文字表記や　文章・パラグラフ"]
        strings.each do |string|
        TokenTestHelper.classify!(
            string,
          ) do |token|
            assert_equal :string_const, token.type
          end
        end
      end
    end
  end
end
