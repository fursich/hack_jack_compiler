require 'test_helper'

module JackCompiler
  module Parser
    module TokenContainerTestHelper
      def self.initialize_with_input(tokens, &block)
        container = JackCompiler::Parser::TokenContainer.new(tokens)

        block.call container
      end
    end

    class TestParserTokenContainer < Minitest::Test
      def test_tokens
        TokenContainerTestHelper.initialize_with_input(
          ['foo', :bar]
        ) do |container|
          assert_equal ['foo', :bar], container.tokens
        end
      end

      def test_size
        TokenContainerTestHelper.initialize_with_input(
          [:foo, :bar, 'baz']
        ) do |container|
          assert_equal 3, container.size
        end
      end

      def test_pop
        tokens = %w[aaa b cc ddddd eeee]

        TokenContainerTestHelper.initialize_with_input(
          tokens
        ) do |container|
          tokens.each do |token|
            assert_equal token, container.pop
          end
        end
      end

      def test_current_token
        tokens = %w[aa bbbbb -1 foo bar baz]

        TokenContainerTestHelper.initialize_with_input(
          tokens
        ) do |container|
          tokens.each do |token|
            assert_equal token, container.current_token
            container.pop
          end

          assert_nil container.current_token
        end
      end

      def test_next_token
        tokens = (10000..10010).to_a

        TokenContainerTestHelper.initialize_with_input(
          tokens
        ) do |container|
          tokens.size.times do |i|
            if i < container.size - 1
              assert_equal tokens[i+1], container.next_token
            else
              assert_nil container.next_token
            end

            container.pop
          end
        end
      end

      def test_peep
        tokens = %w[xxx yyy foo-bar-bar baz -100]

        TokenContainerTestHelper.initialize_with_input(
          tokens
        ) do |container|
          tokens.size.times do |i|
            assert_equal tokens[i], container.peep(i)
          end
          assert_nil container.peep(tokens.size)

          container.pop
          tokens.size.times do |i|
            assert_equal tokens[i], container.peep(i-1)
          end

          container.pop
          tokens.size.times do |i|
            assert_equal tokens[i], container.peep(i-2)
          end

          assert_nil container.peep(-3)
        end
      end
    end
  end
end
