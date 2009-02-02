require 'rubygems'
require 'rake'

# https://wiki.mozilla.org/Labs/Weave/0.3/Setup/Server
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

end
