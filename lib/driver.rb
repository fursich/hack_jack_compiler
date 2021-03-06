# usage
# load 'lib/driver.rb'
# compiler = JackCompiler::Driver.new('Main.jack')
# compiler.run

require 'forwardable'

require_relative 'utils/fileio'
require_relative 'utils/inflector'

require_relative 'errors'
require_relative 'core'

module JackCompiler
  class Driver
    attr_reader :sources

    def initialize(path, output: :vm, debug: false)
      @debug        = debug
      @output       = output # either :xml (as parse tree) or :vm (compiled)

      expand_filenames!(path)
      @raw_sources   = retrive_sources
    end

    def run
      @compiled_codes = []
      @raw_sources.each do |filename, raw_source|
        compiler_core = JackCompiler::Core.new(raw_source, filename: filename, debug: @debug).tap(&:process)

        case @output
        when :vm
          @compiled_codes << compiler_core.transformer.print
          output_filename = filename.sub_ext('.vm')
        when :xml
          @compiled_codes << compiler_core.parser.to_xml
          output_filename = filename.sub_ext('.xml')
        end

        write_file(@compiled_codes.last, filename: output_filename)
      end
    end

    private

    def retrive_sources
      @input_filenames.map do |filename|
        [filename, read_from_file(filename)]
      end
    end

    def read_from_file(filename)
      FileIO.new(filename).read
    end

    def write_file(text, filename:)
      FileIO.new(filename).write(text)
    end

    def expand_filenames!(path)
      unless path && File.exist?(path)
        raise FileError, "No such file found: #{path}\nplease specify valid path of a *.jack file, or a directory including *.jack file(s))"
      end

      pathname = Pathname.new(path)

      if pathname.directory?
        @compilation_mode = :integrated
        @input_filenames = pathname.glob('*.jack')

        validate_file_structure_with_integrated_mode!(pathname)
      else
        @compilation_mode = :single_file
        raise FileError, 'illegal file type' if pathname.extname != '.jack'
        @input_filenames = [pathname]
      end
    end

    def validate_file_structure_with_integrated_mode!(pathname)
      return unless @compilation_mode == :integrated

      raise FileError, "no file(s) found in the directory: #{pathname}" if @input_filenames.empty?
      raise FileError, "cannot find Main.jack in the directory: #{pathname}" unless @input_filenames.map{ |file| file.basename.to_s }.one?('Main.jack')
    end
  end
end
