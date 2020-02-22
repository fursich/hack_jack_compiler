module JackCompiler
  module Parser
    class ParseError              < JackCompiler::Error; end
    class UndefinedTokenPattern   < ParseError; end
  end
end
