#!/bin/bash

if [[ $# -eq 0 ]];then
  echo
  echo 'specify a path to the directory where the source directories exists'
  echo 'usage: compile_sample_files [path]'

  exit 1
fi

for filename in "$1"/*; do
  echo "checking $filename"
  [ -e $filename ] || continue
  echo "compiling $filename"
  { bin/run $filename; } || exit 1
done

echo 'successfully finished with no error(s)'

