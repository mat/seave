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

  def test_create_user_bad_username
    create_user("\]=*")
    assert_equal 'Invalid characters in username', body
    assert_equal 400, status
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

  def test_udpate_user_missing_username
    post "/#{ADMIN_PREFIX}", 
        "function" => "update", 
        "pass" => PASSWORD,
        "secret" => ADMIN_SECRET
    assert_equal INVALID_USERNAME, body
    assert_equal 404, status
  end

  def test_udpate_user_not_found
    post "/#{ADMIN_PREFIX}", 
        "function" => "update", 
        "user" => 'wrong password', 
        "pass" => PASSWORD,
        "secret" => ADMIN_SECRET
    assert_equal 'User not found', body
    assert_equal 404, status
  end

  def test_udpate_user_missing_pass
    post "/#{ADMIN_PREFIX}", 
        "function" => "update", 
        "user" => USERNAME, 
        "secret" => ADMIN_SECRET
    assert_equal MISSING_PASSWORD, body
    assert_equal 404, status
  end

  def test_udpate_user
    create_user # otherwise we would get a "404 User not found."
    post "/#{ADMIN_PREFIX}", 
        "function" => "update", 
        "user" => USERNAME, 
        "pass" => 'new pass',
        "secret" => ADMIN_SECRET
    assert_equal "success", body
    assert_equal 200, status
  end

end

