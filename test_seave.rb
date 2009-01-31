#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'
require 'sinatra/test/unit'
require 'seave'

#PROTOCOL     = 'http'
#SERVER       = 'localhost:4567'
USERNAME     = 'tom'
PASSWORD     = 'test123'
ADMIN_SECRET = 'bad secret'
PREFIX       = 'weave/0.3'
ADMIN_PREFIX = 'weave/admin'

class AdminTest < Test::Unit::TestCase

#		#create the user
#			$req = POST "$PROTOCOL://$SERVER/$ADMIN_PREFIX", ['function' => 'create', 'user' => $USERNAME, 'pass' => $PASSWORD, 'secret' => $ADMIN_SECRET];
#			$req->content_type('application/x-www-form-urlencoded');
#			$result = $ua->request($req)->content();
#			print "create user: $result\n" if $VERBOSE;
#		
#			#create the user again
#			$req = POST "$PROTOCOL://$SERVER/$ADMIN_PREFIX", ['function' => 'create', 'user' => $USERNAME, 'pass' => $PASSWORD, 'secret' => $ADMIN_SECRET];
#			$req->content_type('application/x-www-form-urlencoded');
#			$result = $ua->request($req)->content();
#			print "create user again (should fail): $result\n" if $VERBOSE;


  def test_create_user
    post "/#{ADMIN_PREFIX}", "function" => "create", "user" => USERNAME, "pass" => PASSWORD, "secret" => ADMIN_SECRET
    assert_equal 'success', body
    assert_equal 200, status
  end

  def test_create_user_twice
    post "/#{ADMIN_PREFIX}", "function" => "create", "user" => USERNAME, "pass" => PASSWORD, "secret" => ADMIN_SECRET
    assert_equal 'success', body
    assert_equal 200, status

    post "/#{ADMIN_PREFIX}", "function" => "create", "user" => USERNAME, "pass" => PASSWORD, "secret" => ADMIN_SECRET
    assert_equal 'User already exists', body
    assert_equal 400, status
  end

#  def test_hi
#    get '/hi'
#    assert_equal 200, status
#    assert_equal 'Hi!', body
#  end
#
#  def test_with_agent
#    get '/', :agent => 'Songbird'
#    assert_equal "Home sweet home.", body
#  end
end

