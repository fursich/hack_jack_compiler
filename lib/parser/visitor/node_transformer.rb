module JackCompiler
  module Parser
    class NodeTransformer
      def initialize(factory)
        @factory = factory
      end

      def visit(root)
        root.accept(self)
      end

      def visit_variable(node)
        case node.kind
        when :class
          classVarDec_and_subroutineDec = node.children[3..-2]
          @factory.new(:class).build(
            children: 
              classVarDec_and_subroutineDec.map { |child|
                child.accept(self)
              }.compact.flatten,
            name: node.child(1).value
          )
        when :classVarDec
          # nop
          # already registered
        when :subroutineDec
          subroutineBody = node.children.last
          
          @factory.new(:subroutineDec).build(
            children: [*subroutineBody.accept(self)],
            name: node.child(2).value,
            kind: node.child(0).value,
            returnType: node.child(1).value,
          )
        when :subroutineBody
          varDec_and_statements = node.children[1..-2]

          varDec_and_statements.map { |child|
            child.accept(self)
          }.compact.flatten
        when :varDec
          # nop
          # already registered
        when :statements
          node.children.map { |child|
            child.accept(self)
          }.flatten
        when :statement
          node.children.map { |child|
            child.accept(self)
          }.flatten
        when :letStatement
          varName = node.child(1).value
          index =
            if node.child(2).value == :'['
              node.child(3).accept(self)
            else
              0
            end
          lvalue = @factory.new(:variableAccess).build(
            name: varName,
            index: index,
          )
          rvalue = node.child(-2).accept(self)

          @factory.new(:let).build(
            lvalue: lvalue,
            rvalue: rvalue
          )
        when :ifStatement
          cond = node.child(2).accept(self)
          thenClause = node.child(5).accept(self)
          elseClause = node.child(9)&.accept(self) # could be nil

          @factory.new(:if).build(
            cond:       cond,
            thenClause: thenClause,
            elseClause: elseClause,
          )
        when :whileStatement
          cond = node.child(2).accept(self)
          whileClause = node.child(5).accept(self)

          @factory.new(:while).build(
            cond:        cond,
            whileClause: whileClause,
          )
        when :doStatement
          subroutineName = node.child(-5).value
          args = node.child(-3).accept(self)
          receiver = node.child(1).value

          @factory.new(:subroutineCall).build(
            name: subroutineName,
            args: args,
            scope: node.scope,
            receiver: receiver,
          )
        when :returnStatement
          returnValue = 
            if node.children.size == 3
              node.child(1).accept(self)
            else
              nil
            end

          @factory.new(:return).build(
            returnValue: returnValue
          )
        when :subroutineCall
          subroutineName = node.child(-4).value
          args = node.child(-2).accept(self)
          receiver =
            if node.child.value == '.'
              node.child(0).value
            else
              nil
            end

          @factory.new(:subroutineCall).build(
            name: subroutineName,
            args: args,
            scope: @node.scope,
            receiver: receiver,
          )
        when :expressionList
          return if node.children.empty?

          node.children[1..-1].each_slice(2).map { |expression, _|
            expression.accept(self)
          }
        when :expression
          prev_term = node.child(0).accept(self)
          node.children[1..-1].each_slice(2).each do |op, expression|
            prev_term = @factory.new(op.value).build(
              rvalue: prev_term,
              lvalue: expression.accept(self)
            )
          end
          prev_term
        when :term
          case node.children.size
          when 1
            node.child(0).accept(self)
          when 2 # has to be unaryOp
            @factory.new(node.child(0).value).build(
              lvalue: node.child(1).accept(self)
            )
          when 3 # (expression)
            node.child(1).accept(self)
          when 4 # has to be array access
            varName = node.child(0).value
            index = node.child(2).accept(self)
            @factory.new(:variableAccess).build(
              name: varName,
              index: index,
            )
          end
        else
          raise
        end
      end

      def visit_terminal(node)
        case node.kind
        when :integer
          @factory.new(:constant).build(
            value: node.value
          )
        when :string
          @factory.new(:string).build(
            value: node.value
          )
        when :keyword
          @factory.new(node.value).build(
          )
        when :identifier
          @factory.new(:varName).build(
            value: node.value,
            scope: node.scope
          )
        else
          raise
        end
      end
    end
  end
end
