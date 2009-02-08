require 'rubygems'
require 'rake'

# https://wiki.mozilla.org/Labs/Weave/0.3/Setup/Server
# id needed just for ActiveRecord but it shouldn't hurt.
USER_TABLE = 'CREATE TABLE users (id int, username text primary key, md5 text, email text, status integer, alert text);'
# Again, id is for ActiveRecord, tid is 'real' Weave id.
WBO_TABLE = 'CREATE TABLE wbos (id int, tid text, username text, sortindex int, depth int, collection text, parentid text, encryption text, modified real, encoding text, payload text, primary key (collection,tid) );'

DB_FILE = "db/test.sqlite3"

namespace :db do
  desc "Create in db/test.sqlite3"
  task :create do

    if File.exists?(DB_FILE)
      puts "#{DB_FILE} already exists. Won't overwrite it. Delete first."
    else
      cmd = "sqlite3 #{DB_FILE} '#{USER_TABLE} #{WBO_TABLE}'"
      puts "Created #{DB_FILE}. Bye." if system(cmd) 
    end
  end

  desc "Create example users"
  task :create_users do
    system 'curl -d "function=create"  -d "user=foo" -d "pass=foo" -X POST http://localhost:4567/weave/admin'; puts
    system 'curl -d "function=create"  -d "user=bar" -d "pass=foo" -X POST http://localhost:4567/weave/admin'; puts
    system 'curl -d "function=create"  -d "user=baz" -d "pass=foo" -X POST http://localhost:4567/weave/admin'; puts
  end

  desc "Delete example users"
  task :delete_users do
    system 'curl -d "function=delete"  -d "user=foo" -d "pass=foo" -X POST http://localhost:4567/weave/admin'; puts
    system 'curl -d "function=delete"  -d "user=bar" -d "pass=foo" -X POST http://localhost:4567/weave/admin'; puts
    system 'curl -d "function=delete"  -d "user=baz" -d "pass=foo" -X POST http://localhost:4567/weave/admin'; puts
  end

end

  desc "Test seave against weave with load_data.pl"
  task :xtest do
    puts 'Clearing database.'
    system "sqlite3 #{DB_FILE} 'DELETE FROM users; DELETE FROM wbos;'"
    puts 'Testing Seave'
    system 'perl test/load_data.pl > seave.txt'
    puts 'Clearing database again.'
    system "sqlite3 #{DB_FILE} 'DELETE FROM users; DELETE FROM wbos;'"
    puts 'Testing Weave'
    system 'perl test/load_data.pl weave.local > weave.txt'
    puts 'OK.'
  end

