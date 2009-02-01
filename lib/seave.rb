#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'

configure do
 #
end

users = []

get '/weave/admin' do
  users.inspect
end

post '/weave/admin' do
  if users.empty?
    users << "foo"
    'success'
  else
    'User already exists'
  end
end

get '/' do
  'Home sweet home.'
end

