#!/usr/bin/env ruby


# remember to set RUBYLIB, e.g. RUBYLIB=$PWD ruby example.rb from build dir

require 'fossil'

blob = Fossil::Blob.new
puts "blob is [#{blob}]"
blob.fromString("hello")
puts "blob is [#{blob}]"
# lots of other methods available as Fossil::blob_foo(blob,...)
