#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'
require 'activerecord'
require 'digest/md5'
require 'json'

def md5(str)
  digest = Digest::MD5.hexdigest(str)
end

ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :dbfile =>  'db/test.sqlite3'
)

class User < ActiveRecord::Base
  validates_presence_of :username
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
  else
    [400, 1.to_json]
  end
end

get '/' do
  'Home sweet home.'
end


def admin_create(user, pass)
  unless User.exists?(:username => user)
    User.create!(:username => user, :md5 => md5(pass))
    'success'
  else
    [400, 'User already exists']
  end
end

def admin_check(user)
  (User.exists?(:username => user) ? 1 : 0).to_json
end
