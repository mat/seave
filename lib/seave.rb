#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'
require 'activerecord'

ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :dbfile =>  'db/test.sqlite3'
)

class User < ActiveRecord::Base
  validates_presence_of :username
  validates_presence_of :md5 # password. no sha? hmm.
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
  user = 'tom'
  unless User.exists?(:username => user)
    User.create!( :username => user, :md5 => 'asfdg' )
    'success'
  else
    [400, 'User already exists']
  end
end

get '/' do
  'Home sweet home.'
end

