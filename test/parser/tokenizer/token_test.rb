require 'test_helper'

module JackCompiler
  module Parser
    module TokenTestHelper
      def self.initialize_with_input(type, value, source_location: "123", &block)
        token = JackCompiler::Parser::Token.new(type, value, source_location: source_location)

        block.call token
      end
    end
  
    class TestTokenizerToken < Minitest::Test
      def test_nil_type
        TokenTestHelper.initialize_with_input(
          nil, '   '
        ) do |token|
          assert_raises(JackCompiler::Parser::UndefinedTokenPattern) { token.validate! }
        end
      end
  
      def test_undefined_token_types
        TokenTestHelper.initialize_with_input(
          :undefined, '1_foo'
        ) do |token|
          assert_raises(JackCompiler::Parser::UndefinedTokenPattern) { token.validate! }
        end
      end

      def test_illegal_integer_value
        illegal_integers = [-1, 32768]
        illegal_integers.each do |integer|
          TokenTestHelper.initialize_with_input(
            :integer, integer
          ) do |token|
            assert_raises(JackCompiler::Parser::IllegalIntegerValue) { token.validate! }
          end
        end
      end
  
      def test_getters
        classified_tokens = {
          keyword:    :return,
          symbol:     :'{',
          identifier: :Foo_bar_1,
          integer:    123,
          string:     '文字列　表現',
        }

        classified_tokens.each do |type, value|
          TokenTestHelper.initialize_with_input(
            type, value, source_location: '54321'
          ) do |token|
            assert_equal type,    token.type
            assert_equal value,   token.value
            assert_equal '54321', token.source_location
          end
        end
      end
  
      def test_type_query_methods
        query_methods = {
          keyword:    :keyword?,
          symbol:     :symbol?,
          identifier: :identifier?,
          integer:    :integer?,
          string:     :string?,
        }

        classified_tokens = {
          keyword:    :return,
          symbol:     :'{',
          identifier: :Foo_bar_1,
          integer:    123,
          string:     '文字列　表現',
        }

        classified_tokens.each do |type, value|
        TokenTestHelper.initialize_with_input(
            type, value
          ) do |token|
            query_methods.each do |typename, query|
              if typename == type
                assert token.public_send query
              else
                refute token.public_send query
              end
            end
          end
        end
      end
  
      def test_valid_tokens
        classified_tokens = {
          keyword:                  :return,
          symbol:                   :'{',
          identifier:               :Foo_bar_1,
          integer:                  123,
          string:                   '文字列　表現',
          space:                    '  ',
          singleline_comment:       '//foo bar',
          multiline_comment:        '/*',
          multiline_comment_closer: 'foo bar*/',
        }

        classified_tokens.each do |type, value|
          TokenTestHelper.initialize_with_input(
            type, value
          ) do |token|
            assert token.validate!
          end
        end
      end
    end
  end
end
