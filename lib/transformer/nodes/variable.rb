module JackCompiler
  module Transformer
    module Node
      class Klass < Base
        attr_reader :class_name, :class_var_decs, :subroutine_decs

        def extract_nodes!
          @class_name     = child(1).value
          @class_var_decs  = extract_children(3, kind: :classVarDec)
          @subroutine_decs = extract_children(3 + class_var_decs.size, kind: :subroutineDec)
        end

        def descendants
          [*class_var_decs, *subroutine_decs].compact
        end
      end

      class ClassVarDec < Base
        attr_reader :var_kind, :type, :var_names
        def extract_nodes!
          @var_kind  = child(0).value
          @type      = child(1).value
          @var_names = extract_children(2, kind: :identifier).map(&:value)
        end
      end

      class SubroutineDec < Base
        attr_reader :subroutine_kind, :return_type, :subroutine_name, :parameter_list, :subroutine_body

        def extract_nodes!
          @subroutine_kind = child(0).value
          @return_type     = child(1).value
          @subroutine_name = child(2).value
          @parameter_list  = child(4)
          @subroutine_body = child(6)
        end

        def descendants
          [parameter_list, subroutine_body].compact
        end
      end

      class ParameterList < Base
        attr_reader :parameters

        def extract_nodes!
          types_and_varnames = extract_children(0, kind: [:keyword, :identifier]).map(&:value)
          @parameters =
            types_and_varnames.
            each_slice(2).
            inject({}) { |hash, (type, var)| hash.merge(var => type) } # { var_name => type, .. }
        end
      end

      class SubroutineBody < Base
        attr_reader :var_decs, :statements

        def extract_nodes!
          @var_decs   = extract_children(1, kind: :varDec)
          @statements = child(-2).children # skip Statements, directly link to xxx_statements
        end

        def descendants
          [*var_decs, *statements].compact
        end
      end

      class VarDec < Base
        attr_reader :type, :var_names

        def extract_nodes!
          @type      = child(1).value
          @var_names = extract_children(2, kind: :identifier).map(&:value)
        end
      end

      class Statements < Base
        # skipped
      end

      class LetStatement < Base
        attr_reader :var, :rvalue

        def extract_nodes!
          var_name = child(1).value
          index    = child(3) if child(2).value == :'['
          @var = VariableAccess.new(
            var_name,
            index: index,
            mode:  :set,
          )
          @rvalue   = child(-2)
        end

        def descendants
          [var, rvalue]
        end
      end

      class IfStatement < Base
        attr_reader :condition, :if_statements, :else_statements

        def extract_nodes!
          @condition       = child(2)
          @if_statements   = child(5).children  # skip statements
          @else_statements = child(9)&.children # skip statements
        end

        def descendants
          [condition, *if_statements, *else_statements].compact
        end
      end

      class WhileStatement < Base
        attr_reader :condition, :while_statements

        def extract_nodes!
          @condition          = child(2)
          @while_statements   = child(5).children # skip statements
        end

        def descendants
          [condition, *while_statements]
        end
      end

      class DoStatement < Base
        attr_reader :subroutine_call

        def extract_nodes!
          receiver_name   = child(1).value if child(2).value == :'.'
          subroutine_name = child(-5).value
          arguments       = child(-3).extract_children(0, kind: :expression) # skip expressionList, link to expressions directly
          @subroutine_call = SubroutineCall.new(
            receiver_name:   receiver_name,
            subroutine_name: subroutine_name,
            arguments:       arguments
          )
        end

        def descendants
          [subroutine_call]
        end
      end

      class ReturnStatement < Base
        attr_reader :return_value

        def extract_nodes!
          @return_value = child(1) if child(1).kind == :expression
        end

        def descendants
          [return_value].compact
        end
      end

      class ExpressionList < Base
        # nop
      end

      class Expression < Base
        attr_reader :op, :lvalue, :rvalue

        def extract_nodes!
          @lvalue = child(0)
          if children.size > 1
            @op = child(1).value
            @rvalue = Expression.new(
              :expression, *children[2..-1]
            )
          end
        end

        def descendants
          [lvalue, rvalue].compact
        end
      end

      class Term < Base
        attr_reader :sub_node

        def extract_nodes!
          @sub_node = decompose_sub_node
        end

        def descendants
          [sub_node].compact
        end

        private

        def decompose_sub_node
          case children.size
          when 1 # either one of the following Nodes: integer, string, keyword, varName
            if child(0).kind == :identifier
              VariableAccess.new(
                child(0).value,
              )
            else
              child(0)
            end
          when 2 # unaryOp term
            UnaryOp.new(
              child(0).value,
              term: child(1)
            )
          when 3 # (expression)
            child(1)
          when 4 # arrayName[index], subroutine(expressionList)
            if child(1).value == :'['
              VariableAccess.new(
                child(0).value,
                index: child(2)
              )
            else
              subroutine_name = child(0).value
              arguments       = child(2).extract_children(0, kind: :expression) # skip expressionList, link to expressions directly
              SubroutineCall.new(
                receiver_name:   nil,
                subroutine_name: subroutine_name,
                arguments:       arguments
              )
            end
          when 6 # varName_or_className.subroutine(expressionList)
            receiver_name   = child(0).value
            subroutine_name = child(2).value
            arguments       = child(4).extract_children(0, kind: :expression) # skip expressionList, link to expressions directly
            SubroutineCall.new(
              receiver_name:   receiver_name,
              subroutine_name: subroutine_name,
              arguments:       arguments
            )
          end
        end
      end

      class SubroutineCall < Base
        attr_reader :receiver_name, :subroutine_name, :arguments

        def initialize(receiver_name: nil, subroutine_name:, arguments:)
          super(:subroutineCall)
          @receiver_name   = receiver_name
          @subroutine_name = subroutine_name
          @arguments       = arguments
        end

        def descendants
          [*arguments].compact
        end

        def extract_nodes!
          # nop
        end
      end

      class UnaryOp < Base
        attr_reader :term, :op

        def initialize(op, term:)
          super(:unaryOp)

          @op   = op
          @term = term
        end

        def extract_nodes!
          # nop
        end

        def descendants
          [term]
        end
      end

      class VariableAccess < Base
        attr_reader :name, :index, :mode

        def initialize(name, index: nil, mode: :get)
          super(:variableAccess)

          @name  = name
          @index = index
          @mode  = mode
        end

        def extract_nodes!
          # nop
        end

        def descendants
          [index].compact
        end
      end
    end
  end
end
