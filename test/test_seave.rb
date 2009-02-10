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
ID_PREFIX    = 'wbo'
COLLECTION   = 'bookmarks'

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
    depth     = data[:depth] || id % 3
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
    assert_in_delta timestamp, body, 0.1
  end

  def create_user(user = USERNAME, pass = PASSWORD)
    post_admin "function" => "create", 
               "user" => user, 
               "pass" => pass
  end

  def create_wbo(id = ID, user = USERNAME, collection = COLLECTION)
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
    assert_body INVALID_USERNAME_CHARS
    assert_stat 400
  end

  def test_create_user_twice
    create_user
    assert_success

    create_user
    assert_body USER_ALREADY_EXISTS
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
    assert_body USER_NOT_FOUND
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
    assert_body INVALID_USERNAME_CHARS
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

  def test_get_collection
    collection = 'bookmarks'
    create_wbo(ID  , USERNAME, collection)
    create_wbo(ID+1, USERNAME, collection)
    create_wbo(ID+2, USERNAME, collection)
    create_wbo(ID+3, USERNAME, 'foo')
    create_wbo(ID+4, USERNAME, collection)

    get "#{PREFIX}/#{USERNAME}/#{collection}"
    assert_stat 200
    assert_equal ["\{wbo\}#{ID}",
                  "\{wbo\}#{ID + 1}",
                  "\{wbo\}#{ID + 2}",
                  "\{wbo\}#{ID + 4}",
                 ], JSON.parse(body).sort
  end

  def test_get_collection_sorted_by_index
    collection = 'bookmarks'
    create_wbo(ID  , USERNAME, collection)
    create_wbo(ID+4, USERNAME, collection)
    create_wbo(ID+3, USERNAME, 'foo')
    create_wbo(ID+1, USERNAME, collection)
    create_wbo(ID+2, USERNAME, collection)

    get "#{PREFIX}/#{USERNAME}/#{collection}/?sort=index"
    assert_stat 200
    assert_equal ["\{wbo\}#{ID}",
                  "\{wbo\}#{ID + 1}",
                  "\{wbo\}#{ID + 2}",
                  "\{wbo\}#{ID + 4}",
                 ], JSON.parse(body)
  end

  def test_get_collection_sorted_by_newest
    collection = 'bookmarks'
    create_wbo(ID  , USERNAME, collection)
    create_wbo(ID+4, USERNAME, collection)
    create_wbo(ID+3, USERNAME, 'foo')
    create_wbo(ID+1, USERNAME, collection)
    create_wbo(ID+2, USERNAME, collection)

    get "#{PREFIX}/#{USERNAME}/#{collection}/?sort=newest"
    assert_stat 200
    assert_equal ["\{wbo\}#{ID+2}",
                  "\{wbo\}#{ID+1}",
                  "\{wbo\}#{ID+4}",
                  "\{wbo\}#{ID}",
                 ], JSON.parse(body)
  end

  def test_get_collection_sorted_by_oldest
    collection = 'bookmarks'
    create_wbo(ID  , USERNAME, collection)
    create_wbo(ID+4, USERNAME, collection)
    create_wbo(ID+3, USERNAME, 'foo')
    create_wbo(ID+1, USERNAME, collection)
    create_wbo(ID+2, USERNAME, collection)

    get "#{PREFIX}/#{USERNAME}/#{collection}/?sort=oldest"
    assert_stat 200
    assert_equal ["\{wbo\}#{ID}",
                  "\{wbo\}#{ID+4}",
                  "\{wbo\}#{ID+1}",
                  "\{wbo\}#{ID+2}",
                 ], JSON.parse(body)
  end

  def test_get_collection_sorted_by_depthindex
    collection = 'bookmarks'
    create_wbo(ID  , USERNAME, collection)
    create_wbo(ID+4, USERNAME, collection)
    create_wbo(ID+3, USERNAME, 'foo')
    create_wbo(ID+1, USERNAME, collection)
    create_wbo(ID+2, USERNAME, collection)

    get "#{PREFIX}/#{USERNAME}/#{collection}/?sort=depthindex"
    assert_stat 200
    assert_equal ["\{wbo\}#{ID}",
                  "\{wbo\}#{ID+1}",
                  "\{wbo\}#{ID+4}",
                  "\{wbo\}#{ID+2}",
                 ], JSON.parse(body)
  end

  def test_get_wbo
    create_wbo
    get URI.escape("#{PREFIX}/#{USERNAME}/#{COLLECTION}/{#{ID_PREFIX}}#{ID}")
    assert_stat 200

    created_wbo = JSON.parse(wbo_as_json)
    created_wbo['collection'] = COLLECTION

    returned_wbo = JSON.parse(body)
    returned_wbo.delete('modified')

    assert_equal created_wbo, returned_wbo
  end

  def test_get_non_existent_wbo
    get URI.escape("#{PREFIX}/#{USERNAME}/#{COLLECTION}/{#{ID_PREFIX}#{ID}}")
    assert_stat 404
    assert_body RECORD_NOT_FOUND
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

  def test_delete_whole_collection
    create_wbo(ID)
    get URI.escape("#{PREFIX}/#{USERNAME}/#{COLLECTION}/{#{ID_PREFIX}}#{ID}")
    assert_stat 200

    create_wbo(ID+1)
    get URI.escape("#{PREFIX}/#{USERNAME}/#{COLLECTION}/{#{ID_PREFIX}}#{ID+1}")
    assert_stat 200

    create_wbo(ID+2)
    get URI.escape("#{PREFIX}/#{USERNAME}/#{COLLECTION}/{#{ID_PREFIX}}#{ID+2}")
    assert_stat 200

    delete "#{PREFIX}/#{USERNAME}/#{COLLECTION}/"
    assert_stat 200
    assert_timestamp_body

    get URI.escape("#{PREFIX}/#{USERNAME}/#{COLLECTION}/{#{ID_PREFIX}}#{ID}")
    assert_body RECORD_NOT_FOUND

    get URI.escape("#{PREFIX}/#{USERNAME}/#{COLLECTION}/{#{ID_PREFIX}}#{ID+1}")
    assert_body RECORD_NOT_FOUND

    get URI.escape("#{PREFIX}/#{USERNAME}/#{COLLECTION}/{#{ID_PREFIX}}#{ID+2}")
    assert_body RECORD_NOT_FOUND
  end

  def test_delete_whole_collection_with_unsupported_options
    delete "#{PREFIX}/#{USERNAME}/#{COLLECTION}/?parentid=#{ID_PREFIX}1&limit=2"
    assert_stat 501
    assert_body NOT_SUPPORTED

    delete "#{PREFIX}/#{USERNAME}/#{COLLECTION}/?sort&limit=2"
    assert_stat 501
    assert_body NOT_SUPPORTED
  end

  def test_delete_collection_but_only_certain_parentids
    create_wbo(ID)
    get URI.escape("#{PREFIX}/#{USERNAME}/#{COLLECTION}/{#{ID_PREFIX}}#{ID}")
    assert_stat 200

    create_wbo(ID+1)
    get URI.escape("#{PREFIX}/#{USERNAME}/#{COLLECTION}/{#{ID_PREFIX}}#{ID+1}")
    assert_stat 200

    create_wbo(ID+2)
    get URI.escape("#{PREFIX}/#{USERNAME}/#{COLLECTION}/{#{ID_PREFIX}}#{ID+2}")
    assert_stat 200

    create_wbo(ID+3)
    get URI.escape("#{PREFIX}/#{USERNAME}/#{COLLECTION}/{#{ID_PREFIX}}#{ID+3}")
    assert_stat 200

    delete URI.escape "#{PREFIX}/#{USERNAME}/#{COLLECTION}/?parentid={#{ID_PREFIX}}0"
    assert_stat 200
    assert_timestamp_body

    get URI.escape("#{PREFIX}/#{USERNAME}/#{COLLECTION}/{#{ID_PREFIX}}#{ID}")
    assert_body RECORD_NOT_FOUND
    get URI.escape("#{PREFIX}/#{USERNAME}/#{COLLECTION}/{#{ID_PREFIX}}#{ID+3}")
    assert_body RECORD_NOT_FOUND

    get URI.escape("#{PREFIX}/#{USERNAME}/#{COLLECTION}/{#{ID_PREFIX}}#{ID+1}")
    assert_stat 200
    get URI.escape("#{PREFIX}/#{USERNAME}/#{COLLECTION}/{#{ID_PREFIX}}#{ID+2}")
    assert_stat 200
  end
end

