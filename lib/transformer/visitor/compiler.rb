module JackCompiler
  module Transformer
    class Compiler
      def initialize(symbol_table)
        @symbol_table = symbol_table
        @label = LabelGenerator.new
      end

      class LabelGenerator
        def initialize
          @count = 0
        end

        def for(str)
          "label#{@count}.#{str}"
        end

        def increment!
          @count += 1
        end
      end

      UNARY_OP_SYMBOLS = {
        '-': :neg,
        '~': :not,
      }

      BINARY_OP_SYMBOLS = {
        '+': :add,
        '-': :sub,
        '*': :'call Math.multiply 2',
        '/': :'call Math.devide 2',
        '&': :and,
        '|': :or,
        '>': :gt,
        '<': :lt,
        '=': :eq,
      }

      def visit(node)
        case node.kind
        when :class
          node.subroutine_decs.flat_map {|sub_node| sub_node.accept(self) }
        when :subroutineDec
          statements      = node.subroutine_body.accept(self)
          local_var_count = @symbol_table.size_of(:local, scope: node.subroutine_name)

          subroutine      = @symbol_table.lookup_subroutine(node.scope)
          sentences =
            case subroutine.kind
            when :constructor
              field_size = @symbol_table.size_of(:field, scope: :class)
              <<~VMCODE
                function #{@symbol_table.class_name}.#{node.subroutine_name} #{local_var_count}
                push constant #{field_size}
                call Memory.alloc 1
                pop pointer 0
              VMCODE
            when :method
              <<~VMCODE
                function #{@symbol_table.class_name}.#{node.subroutine_name} #{local_var_count}
                push argument 0
                pop pointer 0
              VMCODE
            when :function
              <<~VMCODE
                function #{@symbol_table.class_name}.#{node.subroutine_name} #{local_var_count}
              VMCODE
            end
          [
            *sentences.split("\n"),
            *statements
          ]
        when :subroutineBody
          node.statements.flat_map {|sub_node| sub_node.accept(self) }
        when :letStatement
          rvalue         = node.rvalue.accept(self) # expression that represents value to be assigned
          var_assignment = node.var.accept(self)    # variable to assign
          [
            *rvalue,
            *var_assignment
          ]
        when :ifStatement
          condition       = node.condition.accept(self) # expression that represents value to be assigned
          if_statements   = node.if_statements.map { |sub_node| sub_node.accept(self) } # expression that represents value to be assigned
          else_statements = node.else_statements&.map { |sub_node| sub_node.accept(self) } # expression that represents value to be assigned

          @label.increment!
          [
            *condition,
            "if_goto #{@label.for(:if)}",
            *else_statements,
            "goto #{@label.for(:if_end)}",
            "label #{@label.for(:if)}",
            *if_statements,
            "label #{@label.for(:if_end)}",
          ]
        when :whileStatement
          condition       = node.condition.accept(self) # expression that represents value to be assigned
          while_statements   = node.while_statements.map { |sub_node| sub_node.accept(self) } # expression that represents value to be assigned

          @label.increment!
          [
            *condition,
            "if_goto #{@label.for(:while)}",
            "goto #{@label.for(:while_end)}",
            "label #{@label.for(:while)}",
            *while_statements,
            "label #{@label.for(:while_end)}",
          ]
        when :doStatement
          call = node.subroutine_call.accept(self)

          [
            *call,
            'pop temp 0'
          ]
        when :returnStatement
          subroutine = @symbol_table.lookup_subroutine(node.scope)

          if subroutine.return_type == :void
            <<~VMCODE.split("\n")
              push constant 0
              return
            VMCODE
          else
            value = node.return_value.accept(self)
            [
              *value,
              'return'
            ]
          end
        when :expression
          if node.op
            lvalue    = node.lvalue.accept(self)
            rvalue    = node.rvalue.accept(self)
            binary_op = BINARY_OP_SYMBOLS[node.op].to_s
            raise unless binary_op # XXX unexecutable operator

            [
              *lvalue,
              *rvalue,
              binary_op,
            ]
          else
            node.lvalue.accept(self)
          end
        when :term
          node.sub_node.accept(self)
        when :subroutineCall
          if node.receiver_name
            # TODO: either compiler or runtime has no idea about
            # whether Xxx.yyy is going to be a method call or
            # non method one (e.g. function)
            # thus, it cannot prevent user from calling irrelevant
            # subroutines, such as: FooClass.a_method()
            # This might cause accidental illegal memory access - since
            # the calee method will set 'this' segment base on
            # caller's 'that' segment (stored at LCL-1 by the caller)
            var = @symbol_table.lookup_variable(node.receiver_name, scope: node.scope)

            if var
              receiver    = var.type

              accessor =
                if var.kind == :field
                  :this
                else
                  var.kind
                end
              caller_object = "push #{accessor} #{var.number}"
              argc = node.arguments.size + 1
            else
              receiver    = node.receiver_name
              caller_object = nil # function or constructor
              argc = node.arguments.size
            end
          else
            # must be a method
            raise unless @symbol_table.lookup_subroutine(node.subroutine_name)

            receiver      = @symbol_table.class_name
            caller_object = 'push pointer 0'
            argc = node.arguments.size + 1
          end

          arguments = node.arguments.flat_map { |arg| arg.accept(self) } unless node.arguments.empty?
          subroutine_accessor = [receiver, node.subroutine_name].join('.')

          [
            caller_object,
            *arguments,
            "call #{subroutine_accessor} #{argc}"
          ].compact
        when :unaryOp
          value    = node.term.accept(self)
          unary_op = UNARY_OP_SYMBOLS[node.op].to_s
          raise unless unary_op # XXX unexecutable operator

          [
            *value,
            *unary_op,
          ]
        when :variableAccess
          var = @symbol_table.lookup_variable(node.name, scope: node.scope)
          raise unless var # XXX undefined variable

          accessor =
            if var.kind == :field
              :this
            else
              var.kind
            end

          method =
            if node.mode == :get
              :push
            elsif node.mode == :set
              :pop
            end

          if node.index
            index = node.index.accept(self)

            <<~VMCODE.split("\n")
              #{index}
              push #{accessor} #{var.number}
              add
              pop pointer 1
              #{method} that 0
            VMCODE
          else
            ["#{method} #{accessor} #{var.number}"]
          end
        when :integer
          "push constant #{node.value}"
        when :string
          # use this for the base address, so that it can be preserved during the following function calls
          build_string = <<~VMCODE.split("\n")
            push constant #{node.value.size}
            call String.new 1
            pop pointer 0
          VMCODE
          set_chars = node.value.each_char.map.with_index { |c, i|
            <<~VMCODE.split("\n")
              pop pointer 0
              push constant #{i}
              push constant #{c}
              call setChatAt 3
              pop temp 0
            VMCODE
          }
          [
            *build_string,
            *set_chars,
          ]
        when :keyword
          case node.value
          when :true
            <<~VMCODE.split("\n")
              push constant 1
              neg
            VMCODE
          when :false, :null
            ['push constant 0']
          when :this
            ['push pointer 0']
          else
            raise # XXX a node must be one of the above
          end
        else
          raise # XXX a node must be one of the above
        end
      end
    end
  end
end
