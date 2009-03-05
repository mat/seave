require 'rubygems'
require 'rake'
require 'activerecord'

DB_FILE = "db/test.sqlite3"

desc "Starts the weave server"
task :start do
  unless File.exists?('config.yml')
    puts "config.yml missing, please create one first."
  else
    puts 'Launching thin server.'
    `thin -C config.yml -R config.ru start`
  end
end

namespace :db do
  desc "Create in db/test.sqlite3"
  task :create do

    if File.exists?(DB_FILE)
      puts "#{DB_FILE} already exists. Won't overwrite it. Delete first with rake db:destroy."
    else
      ActiveRecord::Base.establish_connection(
        :adapter => 'sqlite3',
        :dbfile =>  DB_FILE)

      ActiveRecord::Base.logger = Logger.new(STDOUT)

      # https://wiki.mozilla.org/Labs/Weave/0.3/Setup/Server
      ActiveRecord::Schema.define do
        create_table :users do |t|
          t.string  :username, :limit => 32, :null => false
          t.text    :md5,      :limit => 32, :null => false
          t.text    :email,    :limit => 64
          t.integer :status,   :limit => 4 # tinyint
          t.text    :alert
        end
        add_index :users, :username, :unique

        create_table :wbos do |t|
          t.string  :username,   :limit => 32, :null => false
          t.string  :collection, :limit => 64, :null => false
          t.string  :tid,        :limit => 64, :null => false
          t.string  :parentid,   :limit => 64
          t.decimal :modified,   :precision => 12, :scale => 2
          t.integer :sortindex
          t.integer :depth,      :limit => 4 # tinyint
          t.text    :payload,                  :null => false
        end
        add_index :wbos, [:username, :collection, :tid]
        add_index :wbos, [:username, :collection, :parentid]
        add_index :wbos, [:username, :collection, :modified]
      end

    end
  end

  desc "Destroy sqlite3 DB in #{DB_FILE}"
  task :destroy do
    File.delete(DB_FILE) if File.exists?(DB_FILE)
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

namespace :admin do
  desc "Creates a new (user, password) pair. Seave must be running."
  task :create_user do

    require 'net/http'
    require 'highline/import'
    require 'lib/models'
    require 'lib/seave'

    puts "Let's create a new user."
    params = {}
    params["user"] = ask("username: ") { |q| q.validate = User::VALID_NAME }
    params["pass"] = ask("password: ") { |q| q.validate = /.+/ }

    #TODO params["secret"] = ADMIN_SECRET
    params["function"] = "create"

    begin
      uri = URI.parse("http://localhost:4567#{ADMIN_PREFIX}")
      puts Net::HTTP.post_form(uri,params).body
    rescue Errno::ECONNREFUSED => e
      puts 'localhost:4567 unreachable. Run rake start first.'
    end
  end
end
