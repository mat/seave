require 'rubygems'
require 'rake'

# https://wiki.mozilla.org/Labs/Weave/0.3/Setup/Server
# Need id for ActiveRecord, but it shouldn't hurt.
USER_TABLE = 'CREATE TABLE users (id int, username text primary key, md5 text, email text, status integer, alert text);'

namespace :db do
  desc "Create in db/test.sqlite3"
  task :create do

    db_file = "db/test.sqlite3"

    if File.exists?(db_file)
      puts "#{db_file} already exists. Won't overwrite it. Delete first."
    else
      cmd = "sqlite3 #{db_file} '#{USER_TABLE}'"
      puts "Created #{db_file}. Bye." if system(cmd) 
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
