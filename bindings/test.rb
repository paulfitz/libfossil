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

unless File.exist? "test.fossil"
  File.open("data.csv","w") do |file|
    file.write("NAME,AGE\n")
    file.write("Bob,99\n")
    file.write("Sam,156\n")
  end
  File.open("data2.csv","w") do |file|
    file.write("NAME,AGE,MORE\n")
    file.write("Bob,99,frogs\n")
    file.write("Sam,156,space\n")
  end
  fossil(["new","test.fossil"])
  fossil(["open","test.fossil"])
  fossil(["add","data.csv"]);
  fossil(["commit","-m","add some test data"]);
  fossil(["add","data2.csv"]);
  fossil(["commit","-m","add some more test data"]);
  fossil(["close"])
  File.delete "data.csv"
  File.delete "data2.csv"
end


Fossil::args(["fossil","--repository","test.fossil"]) # not needed given fossil open
Fossil::db_find_and_open_repository(0,0)
puts "still here? yay! We have access to our repo."

rc = Fossil::historical_version_of_file("tip","data.csv",blob,nil,nil,nil,0)
puts "return code from historical_version_of_file is #{rc}"
if rc==0
  puts "failure, miserable failure"
end

puts "Here is the current state of one test file:"
puts blob
Fossil::historical_version_of_file("tip","data2.csv",blob,nil,nil,nil,0)
puts "Here is the current state of another test file:"
puts blob

# Hmm, looks like we basically do SQL queries at this point,
# no real need to wrap things up.

puts "Looking at history of data.csv"
q = Fossil::Stmt.new
Fossil::db_prepare1(q,"SELECT datetime(event.mtime,'localtime'), coalesce(event.ecomment, event.comment), coalesce(event.euser, event.user), mlink.pid, mlink.fid, (SELECT uuid FROM blob WHERE rid=mlink.fid) FROM mlink, event WHERE mlink.fnid IN (SELECT fnid FROM filename WHERE name='data.csv') AND event.objid=mlink.mid ORDER BY event.mtime DESC;")
while Fossil::db_is_row(Fossil::db_step(q))==1
  msg = Fossil::db_column_text(q,1)
  id = Fossil::db_column_int(q,3)
  puts "COMMIT MESSAGE: #{msg} // #{id}"
end

# probably need to close some things down?
