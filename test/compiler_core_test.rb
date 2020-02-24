require 'test_helper'

module JackCompiler
  module CompilerCoreTestHelper
    def assert_xml_output(assertion_file, source_file)
      raw_source = FileIO.new(Pathname('test/fixtures').join(source_file)).read
      target_xml = FileIO.new(Pathname('test/fixtures').join(assertion_file)).read

      parser = JackCompiler::Core.new(raw_source, filename: source_file, debug: false).process
      assert_equal target_xml, parser.to_xml
    end
  end

  class TestCompilerCore < Minitest::Test
    include CompilerCoreTestHelper

    def test_array_test
      assert_xml_output 'ArrayTest/Main.xml', 'ArrayTest/Main.jack'
    end

    def test_expression_less_square
      assert_xml_output 'ExpressionLessSquare/Main.xml',       'ExpressionLessSquare/Main.jack'
      assert_xml_output 'ExpressionLessSquare/Square.xml',     'ExpressionLessSquare/Square.jack'
      assert_xml_output 'ExpressionLessSquare/SquareGame.xml', 'ExpressionLessSquare/SquareGame.jack'
    end

    def test_square
      assert_xml_output 'Square/Main.xml',       'Square/Main.jack'
      assert_xml_output 'Square/Square.xml',     'Square/Square.jack'
      assert_xml_output 'Square/SquareGame.xml', 'Square/SquareGame.jack'
    end
  end
end
