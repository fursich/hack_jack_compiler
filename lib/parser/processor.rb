require_relative 'context'
require_relative 'token_container'
require_relative 'node_builder'
require_relative 'nodes/node'
require_relative 'visitor/visitor'

module JackCompiler
  module Parser
    class Processor
      extend Forwardable

      def_delegators :@tokens, :current_token, :next_token
      attr_reader :tokens, :context, :ast

      def initialize(tokens)
        @tokens    = TokenContainer.new(tokens)
        @context   = Context.new
        @location  = current_token&.source_location
      end

      def parse!
        @ast = parse_class
      end

      def parse_class
        with_context(:class) do
          expect!(:class)
          expect!(:identifier)
          expect!(:'{')
          while current_token_is_a?(:static, :field)
            parse_class_var_dec
          end
          while current_token_is_a?(:constructor, :function, :method)
            parse_subroutine_dec
          end
          expect!(:'}')

          return context.current_parent
        end
      end

      def parse_class_var_dec
        with_context(:classVarDec) do
          expect!(:static, :field)
          parse_type
          expect!(:identifier)
          while accept(:',')
            expect!(:identifier)
          end
          expect!(:';')
        end
      end

      def parse_type
        accept_any(:int, :char, :boolean) || expect!(:identifier)
      end

      def parse_subroutine_dec
        with_context(:subroutineDec) do
          expect!(:constructor, :function, :method)
          accept(:void) || parse_type
          expect!(:identifier)
          expect!(:'(')
          parse_parameter_list
          expect!(:')')
          parse_subroutine_body
        end
      end

      def parse_parameter_list
        with_context(:parameterList) do
          if current_token_is_a?(:int, :char, :boolean, :identifier)
            parse_type
            expect!(:identifier)
            while accept(:',')
              parse_type
              expect!(:identifier)
            end
          end
        end
      end

      def parse_subroutine_body
        with_context(:subroutineBody) do
          expect!(:'{')
          while current_token_is_a?(:var)
            parse_var_dec
          end
          parse_statements
          expect!(:'}')
        end
      end

      def parse_var_dec
        with_context(:varDec) do
          expect!(:var)
          parse_type
          expect!(:identifier)
          while accept(:',')
            expect!(:identifier)
          end
          expect!(:';')
        end
      end

      def parse_statements
        with_context(:statements) do
          while true
            if current_token&.is?(:let)
              parse_let_statement
            elsif current_token&.is?(:if)
              parse_if_statement
            elsif current_token&.is?(:while)
              parse_while_statement
            elsif current_token&.is?(:do)
              parse_do_statement
            elsif current_token&.is?(:return)
              parse_return_statement
            else
              break
            end
          end
        end
      end

      def parse_let_statement
        with_context(:letStatement) do
          expect!(:let)
          expect!(:identifier)
          if accept(:'[')
            parse_expression
            expect!(:']')
          end
          expect!(:'=')
          parse_expression
          expect!(:';')
        end
      end

      def parse_if_statement
        with_context(:ifStatement) do
          expect!(:if)

          expect!(:'(')
          parse_expression
          expect!(:')')

          expect!(:'{')
          parse_statements
          expect!(:'}')

          if accept(:else)
            expect!(:'{')
            parse_statements
            expect!(:'}')
          end
        end
      end

      def parse_while_statement
        with_context(:whileStatement) do
          expect!(:while)

          expect!(:'(')
          parse_expression
          expect!(:')')

          expect!(:'{')
          parse_statements
          expect!(:'}')
        end
      end

      def parse_do_statement
        with_context(:doStatement) do
          expect!(:do)

          parse_subroutine_call
          expect!(:';')
        end
      end

      def parse_return_statement
        with_context(:returnStatement) do
          expect!(:return)

          if !current_token_is_a?(:';')
            parse_expression
          end
          expect!(:';')
        end
      end

      def parse_expression
        with_context(:expression) do
          parse_term
          while accept_any(*%i[+ - * / & | > < =])
            parse_term
          end
        end
      end

      def parse_term
        with_context(:term) do
          if accept_any(:string, :integer)
            # nop
          elsif accept_any(:true, :false, :null, :this)
            # nop
          elsif accept(:'(')
            parse_expression
            expect!(:')')
          elsif accept_any(*%i[- ~])
            parse_term
          elsif current_token.is? :identifier
            if next_token&.is?(:'(') || next_token&.is?(:'.')
              parse_subroutine_call
            elsif next_token&.is? :'['
              expect!(:identifier)
              expect!(:'[')
              parse_expression
              expect!(:']')
            else
              expect!(:identifier)
            end
          else
            raise SyntaxError, "syntax error: #{@location}"
          end
        end
      end

      # no need for new context
      def parse_subroutine_call
        expect!(:identifier)
        if accept(:'.')
          expect!(:identifier)
        end

        expect!(:'(')
        parse_expression_list
        expect!(:')')
      end

      def parse_expression_list
        with_context(:expressionList) do
          unless current_token_is_a?(:')')
            parse_expression
            while accept(:',')
              parse_expression
            end
          end
        end
      end

      def connect_parents!
        Parser::ParentConnector.new.visit ast
      end

      def print
        return unless ast

        Parser::SimpleFormatter.new.visit(ast).join("\n") + "\n"
      end

      def to_xml
        return unless ast

        Parser::XMLFormatter.new.visit(ast).join("\n") + "\n"
      end

      private

      def accept(element)
        @location = current_token&.source_location || @location

        if current_token&.is? element
          token = @tokens.pop
          NodeBuilder.register_as_terminal token, context
          true
        else
          false
        end
      end

      def accept_any(*elements)
        elements.any? { |element| accept(element) }
      end

      def expect!(*elements)
        unless accept_any(*elements)
          caller_location = caller.join("\n")

          raise SyntaxError, "\nunexpected token #{current_token.value} detected, while expecting: #{elements.map(&:to_s).join(', or ')}\n\n  #{@location}\n\n#{caller_location}"
        end
        true
      end

      def try(&block)
        block.call
        true
      rescue
        false
      end

      def current_token_is_a?(*elements)
        elements.any? { |element| current_token&.is?(element) }
      end

      def with_context(kind, &block)
        node = NodeBuilder.build_variable(kind)

        context.execute_with(node) do
          block.call
        end
      end
    end
  end
end
