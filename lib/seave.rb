#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'
require 'activerecord'
require 'digest/md5'
require 'json'

INVALID_USERNAME = '3'
MISSING_PASSWORD = '7'

def md5(str)
  digest = Digest::MD5.hexdigest(str)
end

ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :dbfile =>  'db/test.sqlite3'
)

class User < ActiveRecord::Base
  validates_presence_of :username
  validates_format_of   :username, :with => /^[A-Z0-9._-]+/i

  validates_presence_of :md5 # password. no sha? hmm.
  validates_format_of   :md5, :with => /^[0-9a-f]{32,32}$/i
end


configure do
 #
end


get '/users/?' do
  User.all.to_json
end


get '/weave/admin' do
  User.all.inspect
end

post '/weave/admin' do

  function = params[:function]

  if function == 'create'
    admin_create(params[:user], params[:pass])
  elsif function == 'check'
    admin_check(params[:user])
  elsif function == 'update'
    admin_update(params[:user], params[:pass])
  else
    [400, 1.to_json]
  end

end

get '/' do
  'Home sweet home.'
end


def admin_create(user, pass)
  if User.exists?(:username => user)
    [400, 'User already exists']
  else
    begin
      User.create!(:username => user, :md5 => md5(pass))
    rescue
      [400, 'Invalid characters in username']
    else
      'success'
    end
  end
end

def admin_check(user)
  (User.exists?(:username => user) ? 1 : 0).to_json
end

def admin_update(user, newpass)

   if user.nil? || user.empty?
     [404, INVALID_USERNAME]
   elsif newpass.nil? || newpass.empty?
     [404, MISSING_PASSWORD]
   elsif !User.exists?(:username => user)
     [404, 'User not found']
   else
     User.find_by_username(user).update_attributes!(:md5 => md5(newpass))
     [200, "success"]
   end

#  update_attributes!
  #throw :halt, [404, MISSING_PASSWORD] unless User.exists?(:username => user)
end
