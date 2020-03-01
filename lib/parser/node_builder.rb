module JackCompiler
  module Parser
    module NodeBuilder
      class << self
        def register_as_terminal(token, context)
          node = build_terminal(token)
          context.link! node
        end

        def build_variable(type)
          JackCompiler::Parser::Node::Variable.new(
            type
          )
        end

        def build_terminal(token)
          JackCompiler::Parser::Node::Terminal.new(
            token.type,
            token.value,
            source_location: token.source_location,
          )
        end
      end
    end
  end
end
