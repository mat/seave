#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'
require 'activerecord'
require 'digest/md5'
require 'json'
require 'pp'



configure do

  PREFIX       = '/0.3/user'

  ILLEGAL_METHOD   = '1'
  INVALID_USERNAME = '3'
  MISSING_PASSWORD = '7'
  JSON_PARSE_FAILURE = '6'
  INVALID_WBO = '8'

  # TODO: Move back to User again?
  VALID_NAME = /^[A-Z0-9._-]+$/i
ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :dbfile =>  'db/test.sqlite3'
)

end

class User < ActiveRecord::Base
  
  validates_presence_of :username
  validates_format_of   :username, :with => VALID_NAME

  validates_presence_of :md5 # password. no sha? hmm.
  validates_format_of   :md5, :with => /^[0-9a-f]{32,32}$/i
end

class WBO < ActiveRecord::Base
# Weave Basic Object they call it.

  validates_presence_of     :tid
  validates_length_of       :tid, :in => 1..64

  validates_length_of       :parentid, :maximum => 64

  validates_numericality_of :modified

  validates_presence_of     :collection
  validates_length_of       :collection, :maximum => 64 

  validates_numericality_of :depth

  validates_numericality_of :sortindex

  validates_presence_of     :payload

  def before_validation
    self.modified = Time.now.to_f
  end

  # TODO use :scope
  def WBO.collections(user)
    find_by_sql( ['SELECT DISTINCT collection FROM wbos WHERE username = ?',user])
  end
end


def md5(str)
  digest = Digest::MD5.hexdigest(str)
end

def timestamp
 Time.now.to_f.round(2).to_s 
end

put "#{PREFIX}/:user/:collection/?(:weave_id)?" do
  json = request.body.read
  begin
    h = JSON.parse(json)

    # Use id from path if not contained in JSON.
    h['id'] = params['weave_id'] if h['id'].blank?

    # Free 'real' id for ActiveRecord
    h['tid'] = h.delete('id')
    return [400, INVALID_WBO] if h['tid'].blank?

    h['username'] = params[:user]
    h['collection'] = params[:collection]
    WBO.create(h)
  rescue JSON::ParserError
    return [400, JSON_PARSE_FAILURE]
  rescue ActiveRecord::RecordInvalid => e
    return [400, INVALID_WBO + " " + e.to_s]
  end
  
  timestamp
end

get "#{PREFIX}/?" do
  return [400, INVALID_USERNAME]
end

get "#{PREFIX}/:user/?" do
  wbos = WBO.collections(params[:user])
  wbos.map{|wbo| wbo.collection}.to_json
end

get '/users/?' do
  User.all.to_json
end


def not_supported
  [501, 'Not yet supported.']
end

delete "#{PREFIX}/:user/:collection/:id" do
  wbo = WBO.find_by_collection_and_tid(params[:collection], params[:id])
  wbo.destroy! if wbo
  timestamp
end

delete "#{PREFIX}/:user/:collection/?" do
  not_supported
end

post "#{PREFIX}/:user/:collection/?" do
  not_supported
end

get "#{PREFIX}/:user/:collection/?" do
  not_supported
end

get "#{PREFIX}/:user/:collection/:foo?" do
  not_supported
end


get '/weave/admin' do
  User.all.inspect
end

post '/weave/admin' do

  case params[:function]
    when 'create'
      admin_create(params[:user], params[:pass])
    when 'check'
      admin_check(params[:user])
    when 'update'
      admin_update(params[:user], params[:pass])
    when 'delete'
      admin_delete(params[:user])
    else
      [400, "Unknown function"]
  end
end

get '/' do
  'Home sweet home.'
end


def admin_create(user, pass)
  if pass.nil? || pass.empty?
    return [404, MISSING_PASSWORD]
  end

  if User.exists?(:username => user)
    return [400, 'User already exists']
  end

  begin
    User.create!(:username => user, :md5 => md5(pass))
  rescue
    [400, 'Invalid characters in username']
  else
    'success'
  end
end

def admin_check(user)
  if user.nil? || user.empty?
    return [404, INVALID_USERNAME]
  end

  (User.exists?(:username => user) ? 1 : 0).to_s
end

def admin_update(user, newpass)
   if user.nil? || user.empty?
     return [404, INVALID_USERNAME]
   end

   if newpass.nil? || newpass.empty?
     return [404, MISSING_PASSWORD]
   end

   if !User.exists?(:username => user)
     [404, 'User not found']
   else
     User.find_by_username(user).update_attributes!(:md5 => md5(newpass))
     "success"
   end
end

def admin_delete(user)
   if user.nil? || user.empty?
     return [404, INVALID_USERNAME]
   end

   unless user =~ VALID_NAME
     return [400, 'Invalid characters in username']
   end

   unless User.exists?(:username => user)
     return [404, 'User not found']
   end

   if User.delete_all(:username => user) == 1
     'success'
   else
     'Crash!'
   end
end
