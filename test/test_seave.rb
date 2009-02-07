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
ID           = 42

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

  def wbo_as_json(data = {})
    id        = data[:id] || ID
    id_prefix = data[:id_prefix] || 'wbo'
    depth     = data[:depth] || 0
    payload   = data[:payload] || 'foo'

    json = %Q|{"id":"{#{id_prefix}}#{id}",
               "parentid":"{#{id_prefix}}#{id%3}",
               "sortindex":#{id},
               "depth":#{depth},
               "payload":"#{payload}#{id}"}|
  end

  def wbo_as_json_wo_id(data = {})
    wbo_as_json.gsub(/\"id\":\"[^"]*\"/, '"id":""')
  end

  def assert_timestamp_body
    assert_equal timestamp, body
  end

  def create_user(user = USERNAME, pass = PASSWORD)
    post_admin "function" => "create", 
               "user" => user, 
               "pass" => pass
  end

  def create_wbo(id = ID, user = USERNAME, collection = 'bookmarks')
    put "#{PREFIX}/#{user}/#{collection}/#{id}", wbo_as_json(:id => id)
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
    create_user
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
    put "#{PREFIX}/#{USERNAME}/test/#{ID}", wbo_as_json(:id => ID)
    assert_stat 200
    assert_timestamp_body
  end

  def test_put_wbo_w_malformed_json_payload
    put "#{PREFIX}/#{USERNAME}/test/#{ID}", '{:foo[}]'
    assert_stat 400
    assert_body JSON_PARSE_FAILURE 
  end

  def test_put_wbo_w_missing_id_in_json
    put "#{PREFIX}/#{USERNAME}/test/#{ID}", wbo_as_json_wo_id
    assert_stat 200
    assert_timestamp_body
  end

  def test_put_wbo_w_missing_id
    put "#{PREFIX}/#{USERNAME}/test/", wbo_as_json_wo_id
    assert_stat 400
    assert_body INVALID_WBO
  end

  def test_get_wbo_w_missing_username
    get "#{PREFIX}/"
    assert_stat 400
    assert_body INVALID_USERNAME
  end

  def test_get_wbo_for_user
    create_wbo(ID  , USERNAME, 'foo')
    create_wbo(ID+1, USERNAME, 'foo')
    create_wbo(ID+2, USERNAME, 'bar')
    create_wbo(ID+3, USERNAME, 'baz')
    create_wbo(ID+4, USERNAME, 'baz')
    get "#{PREFIX}/#{USERNAME}"
    assert_stat 200
    assert_equal ['bar', 'baz', 'foo'], JSON.parse(body).sort
  end

  def test_delete_single_object
    create_wbo
    assert_stat 200
    assert_timestamp_body

    delete "#{PREFIX}/#{USERNAME}/tom/#{ID}"
    assert_stat 200
    assert_timestamp_body

    # Idempotent
    delete "#{PREFIX}/#{USERNAME}/tom/#{ID}"
    assert_stat 200
    assert_timestamp_body
  end

end

