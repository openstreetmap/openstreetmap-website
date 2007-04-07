class User < ActiveRecord::Base
  require 'xml/libxml'
  require 'digest/md5'

  has_many :traces
  has_many :diary_entries

  validates_confirmation_of :pass_crypt, :message => 'Password must match the confirmation password'
  validates_uniqueness_of :display_name, :allow_nil => true
  validates_uniqueness_of :email
  validates_length_of :pass_crypt, :minimum => 8
  validates_length_of :display_name, :minimum => 3, :allow_nil => true
  validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i

  def set_defaults
    self.creation_time = Time.now
    self.timeout = Time.now
    self.token = User.make_token()
  end
  
  def pass_crypt=(str) 
    write_attribute("pass_crypt", Digest::MD5.hexdigest(str)) 
  end

  def pass_crypt_confirmation=(str) 
    write_attribute("pass_crypt_confirm", Digest::MD5.hexdigest(str)) 
  end
  
  def self.authenticate(email, passwd) 
    find(:first, :conditions => [ "email = ? AND pass_crypt = ?", email, Digest::MD5.hexdigest(passwd)])
  end 

  def self.authenticate_token(token) 
    find(:first, :conditions => [ "token = ? ", token])
  end 
  
  def self.make_token(length=30)
    chars = 'abcdefghijklmnopqrtuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    confirmstring = ''

    length.times do
      confirmstring += chars[(rand * chars.length).to_i].chr
    end

    return confirmstring
  end

  def to_xml
    doc = OSM::API.new.get_xml_doc
    doc.root << to_xml_node()
    return doc
  end

  def to_xml_node
    el1 = XML::Node.new 'user'
    el1['display_name'] = self.display_name.to_s
    el1['account_created'] = self.creation_time.xmlschema
    return el1
  end
end
