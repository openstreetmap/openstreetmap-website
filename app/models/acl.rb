class Acl < ActiveRecord::Base
  def self.match(address, domain = nil)
    if domain
      condition = Acl.where("address >>= ? OR domain = ?", address, domain)
    else
      condition = Acl.where("address >>= ?", address)
    end
  end

  def self.no_account_creation(address, domain = nil)
    self.match(address, domain).where(:k => "no_account_creation").exists?
  end

  def self.no_note_comment(address, domain = nil)
    self.match(address, domain).where(:k => "no_note_comment").exists?
  end

  def self.no_trace_download(address, domain = nil)
    self.match(address, domain).where(:k => "no_trace_download").exists?
  end
end
