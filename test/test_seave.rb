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
ADMIN_PREFIX = 'weave/admin'

class TestSeave < Test::Unit::TestCase

  def setup
    User.delete_all
    WBO.delete_all
  end

  def post_admin(params)
    params["secret"] = ADMIN_SECRET
    post "/#{ADMIN_PREFIX}", params
  end

  def assert_stat(expected_code)
    assert_equal expected_code, status
  end

  def assert_body(expected_str)
    assert_equal expected_str, body
  end

  def assert_success
    assert_equal "success", body
    assert_stat 200
  end

  def ok_wbo_data(id, collection = 'bookmarks')
          {'id' => id, 
            'parentid' => id%3, 
            'sortindex' => id,
            'depth'    => 1,
            'modified' => 5.hours.from_now.to_f,
            'collection' => collection,
            'payload'  => "a89sdmawo58aqlva.8vj2w9fmq2af8vamva98fgqamf"
           }
  end


  def create_user(user = USERNAME, pass = PASSWORD)
    post_admin "function" => "create", 
               "user" => user, 
               "pass" => pass
  end

  def create_wbo(id = 42, user = USERNAME, collection = 'bookmarks')
    json = ok_wbo_data(id, collection).to_json
    put "#{PREFIX}/#{user}/#{collection}/#{id}", json
  end


  def test_wrong_admin_function
    post_admin 'function' => 'foo'
    assert_body 'Unknown function'
    assert_stat 400
  end

  def test_create_user
    create_user
    assert_success
  end

  def test_create_user_bad_username
    create_user("\]=*")
    assert_body 'Invalid characters in username'
    assert_stat 400
  end

  def test_create_user_twice
    create_user
    assert_success

    create_user
    assert_body 'User already exists'
    assert_stat 400
  end

  def test_check_user_existence_missing_username
    post_admin "function" => "check", "user" => nil 
    assert_body INVALID_USERNAME
    assert_stat 404
  end

  def test_check_user_existence
    post_admin "function" => "check",
               "user" => USERNAME 
    assert_body '0'
    assert_stat 200

    create_user
    assert_success

    post_admin "function" => "check", "user" => USERNAME 
    assert_body '1'
    assert_stat 200
  end

  def test_udpate_user_missing_username
    post_admin "function" => "update",  "pass" => PASSWORD
    assert_body INVALID_USERNAME
    assert_stat 404
  end

  def test_udpate_user_not_found
    post_admin "function" => "update", 
        "user" => 'wrong password', 
        "pass" => PASSWORD
    assert_body 'User not found'
    assert_stat 404
  end

  def test_udpate_user_missing_pass
    post_admin "function" => "update", "user" => USERNAME 
    assert_body MISSING_PASSWORD
    assert_stat 404
  end

  def test_udpate_user
    create_user # otherwise we would get a "404 User not found."
    post_admin "function" => "update", 
        "user" => USERNAME, 
        "pass" => 'new pass'
    assert_success
  end

  def test_delete_user_wo_providing_his_name
    post_admin "function" => "delete", "user" => nil
    assert_body INVALID_USERNAME
    assert_stat 404
  end

  def test_delete_user_w_invalid_name
    post_admin "function" => "delete", "user" => 'foo \$* bar'
    assert_body 'Invalid characters in username'
    assert_stat 400
  end

  def test_delete_user
    create_user
    assert_success

    post_admin "function" => "delete", "user" => USERNAME
    assert_success

    post_admin "function" => "check", "user" => USERNAME
    assert_stat 200
    assert_body '0'
  end
	
  def test_put_wbo
    id = 42
    put "#{PREFIX}/#{USERNAME}/test/#{id}", ok_wbo_data(id).to_json
    assert_success
  end

  def test_put_wbo_w_malformed_json_payload
    id = 42
    put "#{PREFIX}/#{USERNAME}/test/#{id}", '{:foo[}]'
    assert_stat 400
    assert_body JSON_PARSE_FAILURE 
  end

  def test_put_wbo_w_missing_id
    id = 42
    wbo_data = ok_wbo_data(id)
    wbo_data.delete('id')
    put "#{PREFIX}/#{USERNAME}/test/#{id}", wbo_data.to_json
    assert_success
  end

  def test_put_wbo_w_missing_modified
    id = 42
    wbo_data = ok_wbo_data(id)
    wbo_data.delete('modified')
    put "#{PREFIX}/#{USERNAME}/test/#{id}", wbo_data.to_json
    assert_stat 400
    assert_body INVALID_WBO
  end

  def test_get_wbo_w_missing_username
    get "#{PREFIX}/"
    assert_stat 400
    assert_body INVALID_USERNAME
  end

  def test_get_wbo_for_user
    create_wbo(42, USERNAME, 'foo')
    create_wbo(43, USERNAME, 'foo')
    create_wbo(44, USERNAME, 'bar')
    create_wbo(45, USERNAME, 'baz')
    create_wbo(46, USERNAME, 'baz')
    get "#{PREFIX}/#{USERNAME}"
    assert_stat 200
    assert_equal ['bar', 'baz', 'foo'], JSON.parse(body).sort
  end

end

