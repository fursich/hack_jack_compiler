require 'test_helper'

module JackCompiler
  module Parser
    module ParserProcessorTestHelper
      def self.parse_with_input(raw_source, filename: 'filename.jack', &block)
        source    = JackCompiler::Source.new(filename).tap { |source| source.store!(raw_source) }
        tokenizer = JackCompiler::Tokenizer::Processor.new(source).tap(&:tokenize!)
        parser    = JackCompiler::Parser::Processor.new(tokenizer.tokens)

        parser.parse!
        block.call parser
      end
    end
  
    class TestParserProcessor < Minitest::Test
      def test_parse
        ParserProcessorTestHelper.parse_with_input(
          raw_source
        ) do |parser|
          assert_equal xml, parser.to_xml
        end
      end

      def raw_source
        <<~"RAW_SOURCE"
          // This file is part of www.nand2tetris.org
          // and the book "The Elements of Computing Systems"
          // by Nisan and Schocken, MIT Press.
          // File name: projects/10/Square/Main.jack
          
          // (derived from projects/09/Square/Main.jack, with testing additions)
          
          /** Initializes a new Square Dance game and starts running it. */
          class Main {
              static boolean test;    // Added for testing -- there is no static keyword
                                      // in the Square files.
              function void main() {
                var SquareGame game;
                let game = SquareGame.new();
                do game.run();
                do game.dispose();
                return;
              }
          
              function void test() {  // Added to test Jack syntax that is not use in
                  var int i, j;       // the Square files.
                  var String s;
                  var Array a;
                  if (false) {
                      let s = "string constant";
                      let s = null;
                      let a[1] = a[2];
                  }
                  else {              // There is no else keyword in the Square files.
                      let i = i * (-j);
                      let j = j / (-2);   // note: unary negate constant 2
                      let i = i | j;
                  }
                  return;
              }
          }
        RAW_SOURCE
      end

      def xml
        <<~XML_OUTPUT
          <class>
            <keyword> class </keyword>
            <identifier> Main </identifier>
            <symbol> { </symbol>
            <classVarDec>
              <keyword> static </keyword>
              <keyword> boolean </keyword>
              <identifier> test </identifier>
              <symbol> ; </symbol>
            </classVarDec>
            <subroutineDec>
              <keyword> function </keyword>
              <keyword> void </keyword>
              <identifier> main </identifier>
              <symbol> ( </symbol>
              <parameterList>
              </parameterList>
              <symbol> ) </symbol>
              <subroutineBody>
                <symbol> { </symbol>
                <varDec>
                  <keyword> var </keyword>
                  <identifier> SquareGame </identifier>
                  <identifier> game </identifier>
                  <symbol> ; </symbol>
                </varDec>
                <statements>
                  <letStatement>
                    <keyword> let </keyword>
                    <identifier> game </identifier>
                    <symbol> = </symbol>
                    <expression>
                      <term>
                        <identifier> SquareGame </identifier>
                        <symbol> . </symbol>
                        <identifier> new </identifier>
                        <symbol> ( </symbol>
                        <expressionList>
                        </expressionList>
                        <symbol> ) </symbol>
                      </term>
                    </expression>
                    <symbol> ; </symbol>
                  </letStatement>
                  <doStatement>
                    <keyword> do </keyword>
                    <identifier> game </identifier>
                    <symbol> . </symbol>
                    <identifier> run </identifier>
                    <symbol> ( </symbol>
                    <expressionList>
                    </expressionList>
                    <symbol> ) </symbol>
                    <symbol> ; </symbol>
                  </doStatement>
                  <doStatement>
                    <keyword> do </keyword>
                    <identifier> game </identifier>
                    <symbol> . </symbol>
                    <identifier> dispose </identifier>
                    <symbol> ( </symbol>
                    <expressionList>
                    </expressionList>
                    <symbol> ) </symbol>
                    <symbol> ; </symbol>
                  </doStatement>
                  <returnStatement>
                    <keyword> return </keyword>
                    <symbol> ; </symbol>
                  </returnStatement>
                </statements>
                <symbol> } </symbol>
              </subroutineBody>
            </subroutineDec>
            <subroutineDec>
              <keyword> function </keyword>
              <keyword> void </keyword>
              <identifier> test </identifier>
              <symbol> ( </symbol>
              <parameterList>
              </parameterList>
              <symbol> ) </symbol>
              <subroutineBody>
                <symbol> { </symbol>
                <varDec>
                  <keyword> var </keyword>
                  <keyword> int </keyword>
                  <identifier> i </identifier>
                  <symbol> , </symbol>
                  <identifier> j </identifier>
                  <symbol> ; </symbol>
                </varDec>
                <varDec>
                  <keyword> var </keyword>
                  <identifier> String </identifier>
                  <identifier> s </identifier>
                  <symbol> ; </symbol>
                </varDec>
                <varDec>
                  <keyword> var </keyword>
                  <identifier> Array </identifier>
                  <identifier> a </identifier>
                  <symbol> ; </symbol>
                </varDec>
                <statements>
                  <ifStatement>
                    <keyword> if </keyword>
                    <symbol> ( </symbol>
                    <expression>
                      <term>
                        <keyword> false </keyword>
                      </term>
                    </expression>
                    <symbol> ) </symbol>
                    <symbol> { </symbol>
                    <statements>
                      <letStatement>
                        <keyword> let </keyword>
                        <identifier> s </identifier>
                        <symbol> = </symbol>
                        <expression>
                          <term>
                            <stringConstant> string constant </stringConstant>
                          </term>
                        </expression>
                        <symbol> ; </symbol>
                      </letStatement>
                      <letStatement>
                        <keyword> let </keyword>
                        <identifier> s </identifier>
                        <symbol> = </symbol>
                        <expression>
                          <term>
                            <keyword> null </keyword>
                          </term>
                        </expression>
                        <symbol> ; </symbol>
                      </letStatement>
                      <letStatement>
                        <keyword> let </keyword>
                        <identifier> a </identifier>
                        <symbol> [ </symbol>
                        <expression>
                          <term>
                            <integerConstant> 1 </integerConstant>
                          </term>
                        </expression>
                        <symbol> ] </symbol>
                        <symbol> = </symbol>
                        <expression>
                          <term>
                            <identifier> a </identifier>
                            <symbol> [ </symbol>
                            <expression>
                              <term>
                                <integerConstant> 2 </integerConstant>
                              </term>
                            </expression>
                            <symbol> ] </symbol>
                          </term>
                        </expression>
                        <symbol> ; </symbol>
                      </letStatement>
                    </statements>
                    <symbol> } </symbol>
                    <keyword> else </keyword>
                    <symbol> { </symbol>
                    <statements>
                      <letStatement>
                        <keyword> let </keyword>
                        <identifier> i </identifier>
                        <symbol> = </symbol>
                        <expression>
                          <term>
                            <identifier> i </identifier>
                          </term>
                          <symbol> * </symbol>
                          <term>
                            <symbol> ( </symbol>
                            <expression>
                              <term>
                                <symbol> - </symbol>
                                <term>
                                  <identifier> j </identifier>
                                </term>
                              </term>
                            </expression>
                            <symbol> ) </symbol>
                          </term>
                        </expression>
                        <symbol> ; </symbol>
                      </letStatement>
                      <letStatement>
                        <keyword> let </keyword>
                        <identifier> j </identifier>
                        <symbol> = </symbol>
                        <expression>
                          <term>
                            <identifier> j </identifier>
                          </term>
                          <symbol> / </symbol>
                          <term>
                            <symbol> ( </symbol>
                            <expression>
                              <term>
                                <symbol> - </symbol>
                                <term>
                                  <integerConstant> 2 </integerConstant>
                                </term>
                              </term>
                            </expression>
                            <symbol> ) </symbol>
                          </term>
                        </expression>
                        <symbol> ; </symbol>
                      </letStatement>
                      <letStatement>
                        <keyword> let </keyword>
                        <identifier> i </identifier>
                        <symbol> = </symbol>
                        <expression>
                          <term>
                            <identifier> i </identifier>
                          </term>
                          <symbol> | </symbol>
                          <term>
                            <identifier> j </identifier>
                          </term>
                        </expression>
                        <symbol> ; </symbol>
                      </letStatement>
                    </statements>
                    <symbol> } </symbol>
                  </ifStatement>
                  <returnStatement>
                    <keyword> return </keyword>
                    <symbol> ; </symbol>
                  </returnStatement>
                </statements>
                <symbol> } </symbol>
              </subroutineBody>
            </subroutineDec>
            <symbol> } </symbol>
          </class>
        XML_OUTPUT
      end
    end
  end
end
