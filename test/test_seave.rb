#!/usr/bin/env ruby

require 'rubygems'
require 'test/unit'
require 'sinatra'
require 'sinatra/test/unit'
require 'lib/seave'
require 'activerecord'

ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :dbfile =>  'db/test.sqlite3'
)

#PROTOCOL     = 'http'
#SERVER       = 'localhost:4567'
USERNAME     = 'tom'
PASSWORD     = 'test123'
ADMIN_SECRET = 'bad secret'
PREFIX       = 'weave/0.3'
ADMIN_PREFIX = 'weave/admin'

class TestSeave < Test::Unit::TestCase

  def setup
    User.delete_all
  end

  def create_user(user = USERNAME, pass = PASSWORD)
   post "/#{ADMIN_PREFIX}", 
        "function" => "create", 
        "user" => user, 
        "pass" => pass,
        "secret" => ADMIN_SECRET
  end

  def test_create_user
    create_user
    assert_equal 'success', body
    assert_equal 200, status
  end

  def test_create_user_twice
    create_user
    assert_equal 'success', body
    assert_equal 200, status

    create_user
    assert_equal 'User already exists', body
    assert_equal 400, status
  end

  def test_check_user_existence
    post "/#{ADMIN_PREFIX}", 
        "function" => "check", 
        "user" => USERNAME, 
        "secret" => ADMIN_SECRET
    assert_equal '0', body
    assert_equal 200, status

    create_user
    assert_equal 'success', body
    assert_equal 200, status

    post "/#{ADMIN_PREFIX}", 
        "function" => "check", 
        "user" => USERNAME, 
        "secret" => ADMIN_SECRET
    assert_equal '1', body
    assert_equal 200, status

  end

end

