module JackCompiler
  module Parser
    module SimpleFormatter
      class << self
        def visit(root)
          root.accept SimpleFormatter
        end

        def visit_variable(node)
          [
            "Variable Node: #{node.type} | parent #{node.parent&.type || '<NO PARENT>'}",
            *node.children.flat_map { |child| child.accept(SimpleFormatter) }.map { |format| "  " + format }
          ]
        end

        def visit_terminal(node)
          "Terminal Node: #{node.type} <#{node.value}> | parent #{node.parent&.type || '<NO PARENT>'}"
        end
      end
    end

    module XMLFormatter
      class << self
        def visit(root)
          root.accept XMLFormatter
        end

        def visit_variable(node)
          [
            "<#{node.type}>",
            *node.children.flat_map { |child| child.accept(XMLFormatter) }.map { |child| "  #{child}" },
            "</#{node.type}>"
          ]
        end

        def visit_terminal(node)
          "<#{type_for_xml(node)}> #{value_for_xml(node)} </#{type_for_xml(node)}>"
        end

        def value_for_xml(node)
          if node.type == :string
            node.value.to_s.gsub(/\A"(.+)"\z/, '\1').encode(xml: :text)
          else
            node.value.to_s.encode(xml: :text)
          end
        end

        def type_for_xml(node)
          case node.type
          when :string
            :stringConstant
          when :integer
            :integerConstant
          else
            node.type
          end
        end
      end
    end
  end
end
