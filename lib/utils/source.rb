module JackCompiler
  class Source
    attr_reader :filename, :source

    def initialize(filename)
      @filename   = filename
      @cursor     = 0
    end

    def store!(raw_source)
      @source = format_sources(raw_source)
    end

    def pop
      @cursor += 1
      @cursor <= size ? code.dup : nil
    end

    def code_at(num)
      source[num-1][:code]
    end

    def location
      SourceLocation.new(self, lineno)
    end

    def to_s
      max_width = Math.log10(size).ceil

      "<file: #{@filename}>\n\n" + @source.map {|line| sprintf("%#{max_width}s %s", "#{line[:lineno]}:", line[:code]) }.join("\n")
    end

    private

    def format_sources(raw_source)
      raw_source.split(/\r?\n/).map.with_index(1){ |code, lineno| { lineno: lineno, code: code } }
    end

    def lineno
      source[@cursor-1][:lineno]
    end

    def code
      source[@cursor-1][:code]
    end

    def size
      source.size
    end
  end

  class SourceLocation
    attr_accessor :source, :lineno

    def initialize(source, lineno)
      @lineno = lineno
      @source = source
    end

    def filename
      source.filename
    end

    def code
      source.code_at(lineno)
    end

    def to_s
      "#{filename}:#{lineno}:#{code}"
    end
  end
end
