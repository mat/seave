#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'
require 'activerecord'
require 'digest/md5'
require 'json'
require 'pp'



configure do

  PREFIX       = '/0.3/user'
  ADMIN_PREFIX = '/weave/admin'

  # Error codes.
  ILLEGAL_METHOD   = '"1"'
  INVALID_USERNAME = '"3"'
  MISSING_PASSWORD = '"7"'
  JSON_PARSE_FAILURE = '"6"'
  INVALID_WBO = '"8"'

  # Error messages.
  USER_ALREADY_EXISTS    = '"User already exists"'
  USER_NOT_FOUND         = '"User not found"'
  INVALID_USERNAME_CHARS = '"Invalid characters in username"'
  RECORD_NOT_FOUND       = '"Record not found"'
  NOT_SUPPORTED          = '"Not supported."'

  # TODO: Move back to User again?
  VALID_NAME = /^[A-Z0-9._-]+$/i

  SUPPORTED_DELETE_PARAMS = %w(username collection parentid)
  SUPPORTED_GET_PARAMS    = %w(username collection parentid sort full)
end

#ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :dbfile =>  'db/test.sqlite3'
)

class User < ActiveRecord::Base
  
  validates_presence_of   :username
  validates_uniqueness_of :username
  validates_format_of     :username, :with => VALID_NAME

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

  validates_numericality_of :depth, :allow_nil => true

  validates_numericality_of :sortindex

  validates_presence_of     :payload

  validate :payload_must_be_json_string

  def payload_must_be_json_string
    unless payload.is_a?(String)
      errors.add(:payload, "needs to be a json-encoded string")
    end
  end

  def before_validation
    self.depth    = nil if self.depth.blank?
    self.modified = Time.now.to_f unless self.modified
  end

  # TODO use :scope
  def WBO.collections(user)
    find_by_sql( ['SELECT DISTINCT collection FROM wbos WHERE username = ?',user])
  end

  def to_json
    json = %Q|
    {"id":"#{self.tid}",
     "parentid":"#{self.parentid}",
     "modified":#{self.modified},
     "depth":#{self.depth},
     "sortindex":#{self.sortindex},
     "payload":"#{self.payload}"}|

     json.gsub!(/\"depth\":.*,/, '') if self.depth.nil?

     json.gsub(/,\n +/, ',').gsub(/^\s+/, '')
  end
end

def timestamp(format = :string)
  return Time.now.to_f.round(2).to_s if format == :string
  return Time.now.to_f.round(2)
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

    if h['payload']
      wbo = WBO.new(h)
      wbo.save!
    else # update existing
      wbo = WBO.find_by_collection_and_tid(h['collection'], h['tid'])
      return [400, INVALID_WBO] unless wbo
      wbo.update_attributes!(h)
    end
  rescue JSON::ParserError
    return [400, JSON_PARSE_FAILURE]
  rescue ActiveRecord::RecordInvalid => e
    return [400, INVALID_WBO]
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
  [501, NOT_SUPPORTED]
end

delete "#{PREFIX}/:user/:collection/:id" do
  wbo = WBO.find_by_collection_and_tid(params[:collection], params[:id])
  wbo.destroy! if wbo
  timestamp
end

delete "#{PREFIX}/:username/:collection/?" do
  return not_supported unless (params.keys - SUPPORTED_DELETE_PARAMS).empty?
  # TODO parentid, older, newer, limit, offset, sort

  WBO.delete_all(params)
  timestamp
end

post "#{PREFIX}/:user/:collection/?" do
  body = request.body.read
  batch = []
  begin
    batch = JSON.parse(body)
  rescue JSON::ParserError
    return [400, JSON_PARSE_FAILURE]
  end

  time = timestamp(:float)
  success_ids = []
  failed_ids  = Hash.new {|hash,key| hash[key] = []}
  batch.each do |data|
    if data['id'].blank?
      failed_ids[data['id']] << 'no id given'
      next
    end

    data['tid']        = data.delete('id') # Free id for ActiveRecord
    data['username']   = params[:user]
    data['collection'] = params[:collection]
    data['modified']   = time
    begin
      wbo = WBO.new(data)
      wbo.save!
    rescue ActiveRecord::RecordInvalid => e
      failed_ids[data['tid']] <<  ''
    else
      success_ids << data['tid']
    end
  end

  failed_ids = [] if failed_ids.empty?

  json = %Q|
   {"modified":#{time.to_json},
    "success":#{success_ids.to_json},
    "failed":#{failed_ids.to_json}}|.gsub(/,\n +/, ',').gsub(/^\s+/, '')
end

get "#{PREFIX}/:username/:collection/?" do
  return not_supported unless (params.keys - SUPPORTED_GET_PARAMS).empty?
  # TODO newer, older, limit, offset

  order = case params['sort']
    when 'index'      : 'sortindex'
    when 'newest'     : 'modified DESC'
    when 'oldest'     : 'modified'
    when 'depthindex' : 'depth, sortindex'
    else nil
  end
  return_full_wbo_data = params['full'] == '1'
  params.delete('full') if params.include?('full')
  params.delete('sort') if params.include?('sort')

  wbos = WBO.all(:conditions => params, :order => order)

  if return_full_wbo_data
    wbos = "[#{wbos.map{|w| w.to_json }}"
  else
    wbos = wbos.map{|w| w.tid }.to_json
  end

  wbos
end

get "#{PREFIX}/:username/:collection/:tid" do
  s = "tid, collection, parentid, modified, depth, sortindex, payload"
  wbo = WBO.first(:conditions => params, :select => s)
  if wbo
    #wbo = wbo.attributes
    #wbo['id'] = wbo.delete('tid')
    wbo.to_json
  else
    [404, RECORD_NOT_FOUND]
  end
end


get "#{ADMIN_PREFIX}" do
  User.all.inspect
end

post "#{ADMIN_PREFIX}" do

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
  'Hello, this is Seave, a 
   <a href="https://wiki.mozilla.org/Labs/Weave/0.3/API">Weave</a>
   server implementation.'
end


def admin_create(user, pass)
  if pass.nil? || pass.empty?
    return [404, MISSING_PASSWORD]
  end

  if User.exists?(:username => user)
    return [400, USER_ALREADY_EXISTS]
  end

  begin
    User.create!(:username => user, :md5 => Digest::MD5.hexdigest(pass))
  rescue
    [400, INVALID_USERNAME_CHARS]
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
     [404, USER_NOT_FOUND]
   else
     u = User.find_by_username(user)
     u.update_attributes!(:md5 => Digest::MD5.hexdigest(newpass))
     "success"
   end
end

def admin_delete(user)
   if user.nil? || user.empty?
     return [404, INVALID_USERNAME]
   end

   unless user =~ VALID_NAME
     return [400, INVALID_USERNAME_CHARS]
   end

   unless User.exists?(:username => user)
     return [404, USER_NOT_FOUND]
   end

   if User.delete_all(:username => user) == 1
     'success'
   else
     'Crash!'
   end
end
