require 'digest/md5'

class User < ActiveRecord::Base
  has_many :traces

  validates_confirmation_of :pass_crypt, :message => 'Password must match the confirmation password'
  validates_uniqueness_of :display_name
  validates_uniqueness_of :email
  validates_length_of :pass_crypt, :minimum => 8
  validates_length_of :display_name, :minimum => 3
  validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i

  def set_defaults
    self.creation_time = Time.now
    self.timeout = Time.now
    self.token = make_token()
  end
  
  def pass_crypt=(str) 
    write_attribute("pass_crypt", Digest::MD5.hexdigest(str)) 
  end 

  def pass_crypt_confirmation=(str) 
    write_attribute("pass_crypt_confirm", Digest::MD5.hexdigest(str)) 
  end 

  def self.authenticate(email, passwd) 
    find_first([ "email = ? AND pass_crypt =?", email, Digest::MD5.hexdigest(passwd) ])
  end 
  
  private
  def make_token
    chars = 'abcdefghijklmnopqrtuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    confirmstring = ''

    30.times do
      confirmstring += chars[(rand * chars.length).to_i].chr
    end

    return confirmstring
  end

end
