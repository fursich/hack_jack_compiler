[![Build Status](https://travis-ci.org/fursich/hack_jack_compiler.svg?branch=master)](https://travis-ci.org/fursich/hack_jack_compiler)

# Hack Jack Compiler
Jack compiler implemented in Ruby

## How to use:
1. clone this repository
2. make sure that Ruby (~> 2.5) is installed
3. install bundler gem (and bundle)
```bash
  $ gem install bundler
  $ bundle install
```
4. compile
- with *.jack files
```bash
  $ ./bin/run path/to/source_code.jack
```
- or with a directory (,which must contain Main.jack)
```bash
  $ ./bin/run path/to/dir_name
```

## Jack language and Hack VM
Origial ideas of Jack laungage, and HACK architecture are introduced in:

#### [The Elements of Computing Systems](https://www.amazon.co.jp/dp/0262640686)

and its [Japanese translation](https://www.amazon.co.jp/dp/4873117127/)

Specifications of Jack language are provided in the above book at chapter 9-11.

- basic ideas/tools are introduced at:

https://www.nand2tetris.org/

- see the publisher's link for datails:

http://mitpress.mit.edu/books/elements-computing-systems
https://www.oreilly.co.jp/books/9784873117126/

