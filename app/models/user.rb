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
    self.token = User.make_token()
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

  def self.authenticate_token(token) 
    find_first([ "token = ? ", token])
  end 
  
  def self.make_token(length=30)
    chars = 'abcdefghijklmnopqrtuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    confirmstring = ''

    length.times do
      confirmstring += chars[(rand * chars.length).to_i].chr
    end

    return confirmstring
  end

end
