require_relative 'utils/source'
require_relative 'tokenizer/processor'
require_relative 'parser/processor'
require_relative 'transformer/processor'

module JackCompiler
  class Core
    attr_reader :source, :tokenizer, :parser, :transformer

    def initialize(raw_source, filename:, debug: false)
      @raw_source = raw_source
      @filename   = filename
      @debug      = debug # TODO
    end

    def process
      @source    = JackCompiler::Source.new(@filename).tap { |source| source.store!(@raw_source) }
      @tokenizer = JackCompiler::Tokenizer::Processor.new(source).tap(&:tokenize!)
      @parser    = JackCompiler::Parser::Processor.new(tokenizer.tokens).tap(&:parse!)
      print parser

      ast = parser.ast
      @transformer = JackCompiler::Transformer::Processor.new(ast)
      transformer.tap(&:transform!).tap(&:analyze_symbols).tap(&:compile)
      self
    end

    def print(parser)
      return unless @debug

      case @debug
      when :xml
        puts parser.to_xml
      when :print
        puts parser.print
      else
        puts parser
      end
    end
  end
end
