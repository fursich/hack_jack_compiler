module JackCompiler
  module Parser
    class SimpleFormatter
      def visit(root)
        root.accept self
      end

      def visit_variable(node)
        [
          "Variable Node: #{node.kind} | parent #{node.parent&.kind || '<NO PARENT>'}",
          *node.children.flat_map { |child| child.accept(self) }.map { |format| "  " + format }
        ]
      end

      def visit_terminal(node)
        "Terminal Node: #{node.kind} <#{node.value}> | parent #{node.parent&.kind || '<NO PARENT>'}"
      end
    end

    class XMLFormatter
      def visit(root)
        root.accept self
      end

      def visit_variable(node)
        [
          "<#{node.kind}>",
          *node.children.flat_map { |child| child.accept(self) }.map { |child| "  #{child}" },
          "</#{node.kind}>"
        ]
      end

      def visit_terminal(node)
        "<#{kind_for_xml(node)}> #{value_for_xml(node)} </#{kind_for_xml(node)}>"
      end

      def value_for_xml(node)
        if node.kind == :string
          node.value.to_s.gsub(/\A"(.+)"\z/, '\1').encode(xml: :text)
        else
          node.value.to_s.encode(xml: :text)
        end
      end

      def kind_for_xml(node)
        case node.kind
        when :string
          :stringConstant
        when :integer
          :integerConstant
        else
          node.kind
        end
      end
    end
  end
end
