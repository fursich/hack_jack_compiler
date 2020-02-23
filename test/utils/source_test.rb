require 'test_helper'
require 'utils/source.rb'

module JackCompiler
  module SourceTestHelper
    def self.build_source(filename='test.rb', &block)
      source = JackCompiler::Source.new(filename)

      block.call source
    end

    def self.source_with_input(raw_source, filename='test.rb', &block)
      source = JackCompiler::Source.new(filename)
      source.store!(raw_source)

      block.call source
    end
  end

  class TestSource < Minitest::Test
    def raw_source
      <<~"RAW_SOURCE".chomp
        Lorem ipsum dolor sit amet, consectetur adipiscing elit,


        sed do eiusmod tempor incididunt ut labore et dolore magna

        aliqua.
      RAW_SOURCE
    end

    def formatted_source
      [
        { lineno: 1, code: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit,' },
        { lineno: 2, code: '' },
        { lineno: 3, code: '' },
        { lineno: 4, code: 'sed do eiusmod tempor incididunt ut labore et dolore magna' },
        { lineno: 5, code: '' },
        { lineno: 6, code: 'aliqua.' },
      ]
    end

    def sources
      [
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit,',
        '',
        '',
        'sed do eiusmod tempor incididunt ut labore et dolore magna',
        '',
        'aliqua.',
      ]
    end

    def test_filename
      filename = "/var/www/shared/foobar.jack"
      SourceTestHelper.build_source(
        filename
      ) do |source|
        assert_equal filename, source.filename
      end
    end

    def test_store
      SourceTestHelper.build_source(
        'filename.jack'
      ) do |source|
        assert_nil source.source
        source.store! raw_source
        assert_equal formatted_source, source.source
      end
    end

    def test_pop
      SourceTestHelper.source_with_input(
        raw_source,
      ) do |source|
        sources.size.times do |i|
          assert_equal sources[i], source.pop
        end

        assert_nil source.pop
      end
    end

    def test_code_at
      SourceTestHelper.source_with_input(
        raw_source,
      ) do |source|
        sources.size.times do |i|
          assert_equal sources[i], source.code_at(i+1)
        end
      end
    end

    def test_location
      SourceTestHelper.source_with_input(
        raw_source,
        'filename.jack'
      ) do |source|
        sources.size.times do |i|
          source.pop
          location = source.location

          assert_instance_of JackCompiler::SourceLocation,   location
          assert_equal source,                               location.source
          assert_equal i+1,                                  location.lineno
          assert_equal 'filename.jack',                      location.filename
          assert_equal sources[i],                           location.code
          assert_match "filename.jack:#{i+1}:#{sources[i]}", location.to_s
        end
      end
    end

    def test_to_s
      printable_format = <<~"PRINTABLE_FORMAT".chomp
        <file: ~/foo/bar/filename.jack>

        1: Lorem ipsum dolor sit amet, consectetur adipiscing elit,
        2: 
        3: 
        4: sed do eiusmod tempor incididunt ut labore et dolore magna
        5: 
        6: aliqua.
      PRINTABLE_FORMAT

      SourceTestHelper.source_with_input(
        raw_source,
        '~/foo/bar/filename.jack'
      ) do |source|
        assert_match printable_format, source.to_s
      end
    end
  end
end
