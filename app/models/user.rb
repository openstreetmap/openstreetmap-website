require 'digest/md5'

class User < ActiveRecord::Base
  has_many :traces

  def passwd=(str) 
    write_attribute("pass_crypt", Digest::MD5.hexdigest(str)) 
  end 

  def passwd
    return self.pass_crypt
  end 

  def self.authenticate(username, passwd) 
    find_first([ "display_name = ? AND pass_crypt =?", 
               username, 
               Digest::MD5.hexdigest(passwd) ]) 
  end 
end
