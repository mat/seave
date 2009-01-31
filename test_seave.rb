#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'
require 'sinatra/test/unit'
require 'seave'

class SeaveTest < Test::Unit::TestCase
  def test_my_default
    get '/'
    assert_equal 'Home sweet home.', @response.body
  end

  def test_hi
    get '/hi'
    assert_equal 200, status
    assert_equal 'Hi!', body
  end

  def test_with_agent
    get '/', :agent => 'Songbird'
    assert_equal "Home sweet home.", body
  end
end

