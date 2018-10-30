#!/bin/sh

for file in *.abc
do
  grep -v '^\s*$' $file >../abc/$file
done
