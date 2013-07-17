#!/usr/bin/env ruby


# remember to set RUBYLIB, e.g. from a "build" directory within source:
#   RUBYLIB=$PWD/lib ruby ../bindings/test.rb

require 'fossil'

blob = Fossil::Blob.new
puts "blob is [#{blob}]"
blob.fromString("hello")
puts "blob is [#{blob}]"
# lots of other methods available as Fossil::blob_foo(blob,...)

def fossil(args)
  # Not dealing yet with fossil's internal state, so do "big"
  # fossil calls in a separate process - not very useful I know
  make_a_repo = fork do
    Fossil::main(["fossil"].concat(args))
  end
  Process.waitpid(make_a_repo)
end

unless File.exist? "data.csv"
  File.open("data.csv","w") do |file|
    file.write("NAME,AGE\n")
    file.write("Bob,99\n")
    file.write("Sam,156\n")
  end
end

unless File.exist? "test.fossil"
  fossil(["new","test.fossil"])
  fossil(["open","test.fossil"])
  fossil(["add","data.csv"]);
  fossil(["commit","-m","add some test data"]);
  # fossil(["close"]) # not yet, unpatched fossil won't let us access
  # files without a tree - fix is easy but not yet offered upstream
end


Fossil::args(["fossil","--repository","test.fossil"]) # not needed given fossil open
Fossil::db_find_and_open_repository(0,0)
puts "still here? yay! We have access to our repo."

rc = Fossil::historical_version_of_file("tip","data.csv",blob,nil,nil,nil,0)
puts "return code from historical_version_of_file is #{rc}"
if rc==0
  puts "failure, miserable failure"
end
puts blob

# probably need to close some things down?
