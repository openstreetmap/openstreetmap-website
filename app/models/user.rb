require 'digest/md5'

class User < ActiveRecord::Base
  has_many :traces

  validates_confirmation_of :pass_crypt

#  def password=(str) 
#    write_attribute("pass_crypt", Digest::MD5.hexdigest(str)) 
#  end 


#  def password
#    return self.pass_crypt
#  end 

#  def self.authenticate(username, passwd) 
#    find_first([ "display_name = ? AND pass_crypt =?", 
#               username, 
#               Digest::MD5.hexdigest(passwd) ]) 
#  end 
end
