module JackCompiler
  module Parser
    module VisitorTestHelper
      def self.build_variable(kind)
        JackCompiler::Parser::Node::Variable.new(
          kind
        )
      end

      def self.build_terminal(kind, value, source_location: 123)
        JackCompiler::Parser::Node::Terminal.new(
          kind,
          value,
          source_location: source_location,
        )
      end

      def self.append_child(node, category: :variable, kind: :term, value: nil)
        child = if category == :variable
                  build_variable(kind)
                else
                  build_terminal(kind, value)
                end
        node.push child
        child
      end

      def self.append_children(node, count, category: :variable, kind: :term, value: nil)
        count.times do
          append_child(node, category: category, kind: kind, value: value)
        end
      end

      def self.build_descendants(node, count:, depth:, kind:, value:)
        if depth > 1
          append_children(node, count, category: :variable, kind: kind)
        elsif depth == 1
          append_children(node, count, category: :terminal, kind: :identifier, value: value)
          return
        else
          raise RuntimeError, 'depth: must be greater than 0'
        end

        node.children.each do |child|
          build_descendants(child, count: count, depth: depth-1, kind: kind, value: value)
        end
      end

      def self.prepare_class(class_name)
        root = build_variable(:class)
        append_child(root, category: :terminal, kind: :keyword,    value: :class)
        append_child(root, category: :terminal, kind: :identifier, value: class_name)
        append_child(root, category: :terminal, kind: :symbol,     value: :'{')

        root
      end

      def self.prepare_class_var_dec(kind, type, *vars)
        body = build_variable(:classVarDec)
        append_child(body, category: :terminal, kind: :keyword, value: kind)
        append_child(body, category: :terminal, kind: :keyword, value: type)

        vars.each do |name|
          append_child(body, category: :terminal, kind: :identifier, value: name)
          if name == vars.last
            append_child(body, category: :terminal, kind: :symbol, value: :';')
          else
            append_child(body, category: :terminal, kind: :symbol, value: :',')
          end
        end

        body
      end

      def self.prepare_subroutine(name, kind, return_type=:void, **vars)
        sub = build_variable(:subroutineDec)
        append_child(sub, category: :terminal, kind: :keyword, value: kind)
        append_child(sub, category: :terminal, kind: :keyword, value: return_type)
        append_child(sub, category: :terminal, kind: :identifier, value: name)
        append_child(sub, category: :terminal, kind: :symbol, value: :'(')

        list = append_child(sub, category: :variable, kind: :parameterList)
        vars.each do |name, type|
          append_child(list, category: :terminal, kind: :keyword, value: type)
          append_child(list, category: :terminal, kind: :identifier, value: name)
        end

        append_child(sub, category: :terminal, kind: :symbol, value: :')')
        append_child(sub, category: :variable, kind: :subroutineBody)

        sub
      end

      def self.prepare_var_dec(type, *vars)
        body = build_variable(:varDec)
        append_child(body, category: :terminal, kind: :keyword, value: :var)
        append_child(body, category: :terminal, kind: :keyword, value: type)

        vars.each do |name|
          append_child(body, category: :terminal, kind: :identifier, value: name)
          if name == vars.last
            append_child(body, category: :terminal, kind: :symbol, value: :';')
          else
            append_child(body, category: :terminal, kind: :symbol, value: :',')
          end
        end

        body
      end

      def self.prepare_simple_exp(kind, value)
        exp = build_variable(:expression)
        append_child(exp, category: :terminal, kind: kind, value: value)
        exp
      end

      def self.prepare_parser(raw_source, filename: 'filename.jack')
        source    = JackCompiler::Source.new(filename).tap { |source| source.store!(raw_source) }
        tokenizer = JackCompiler::Tokenizer::Processor.new(source).tap(&:tokenize!)
        JackCompiler::Parser::Processor.new(tokenizer.tokens)
      end

      def self.prepare_tree(raw_source, root_node:, filename: 'filename.jack')
        parser = prepare_parser(raw_source, filename: filename)
        parser.send "parse_#{root_node}"
      end
    end
  end
end
