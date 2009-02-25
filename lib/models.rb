require 'rubygems'
require 'activerecord'

class User < ActiveRecord::Base
  VALID_NAME = /^[A-Z0-9._-]+$/i

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

