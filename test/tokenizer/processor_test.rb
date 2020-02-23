require 'test_helper'

module JackCompiler
  module Tokenizer
    module TokenizerProcessorTestHelper
      def self.tokenizer_with_input(raw_source, filename: 'filename.jack', &block)
        source = JackCompiler::Source.new(filename).tap { |source| source.store!(raw_source) }
        tokenizer = JackCompiler::Tokenizer::Processor.new(source)

        block.call tokenizer
      end

      def self.tokenize_with_input(text, filename: 'filename.jack', &block)
        source = JackCompiler::Source.new(filename).tap { |source| source.store!(text) }
        tokenizer = JackCompiler::Tokenizer::Processor.new(source)

        block.call tokenizer.tokenize!
      end
    end
  
    class TestTokenizerProcessor < Minitest::Test
      def raw_source
        <<~"RAW_SOURCE"
          // This file is part of www.nand2tetris.org
          // and the book "The Elements of Computing Systems"
          // by Nisan and Schocken, MIT Press.
          // File name: projects/10/ArrayTest/Main.jack
          
          // (identical to projects/09/Average/Main.jack)

          /** Computes the average of a sequence of integers. */
          class Main {
              function void main() {
                  var Array a;
                  var int length;
                  var int i, sum;
          	
          	let length = Keyboard.readInt("HOW MANY NUMBERS? ");
          	let a = Array.new(length);
          	let i = 0;
          	
          	while (i < length) {
          	    let a[i] = Keyboard.readInt("ENTER THE NEXT NUMBER: ");
          	    let i = i + 1;
          	}
          	
          	let i = 0;
          	let sum = 0;
          	
          	while (i < length) {
          	    let sum = sum + a[i];
          	    let i = i + 1;
          	}
          	
          	do Output.printString("THE AVERAGE IS: ");
          	do Output.printInt(sum / length);
          	do Output.println();
          	
          	return;
              }
          }
        RAW_SOURCE
      end

      def test_tokens
        TokenizerProcessorTestHelper.tokenizer_with_input(
          raw_source
        ) do |tokenizer|
          assert_empty tokenizer.tokens
          tokenizer.tokenize!

          assert_instance_of JackCompiler::Tokenizer::Token, tokenizer.tokens.first
          assert_equal :keyword, tokenizer.tokens.first.type
          assert_equal :class , tokenizer.tokens.first.value
          assert_equal 140, tokenizer.tokens.count
        end
      end
    end
  end
end
