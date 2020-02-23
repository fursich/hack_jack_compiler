module JackCompiler
  class Error < StandardError; end
  class FileError < Error; end

  class ParseError              < JackCompiler::Error; end
  class UndefinedTokenPattern   < ParseError; end
  class IllegalIntegerValue     < ParseError; end
  class SyntaxError             < ParseError; end
end
