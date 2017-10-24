# == Schema Information
#
# Table name: acls
#
#  id      :integer          not null, primary key
#  address :inet
#  k       :string           not null
#  v       :string
#  domain  :string
#
# Indexes
#
#  acls_k_idx  (k)
#

class Acl < ActiveRecord::Base
  validates :k, :presence => true

  def self.match(address, domain = nil)
    if domain
      Acl.where("address >>= ? OR domain = ?", address, domain)
    else
      Acl.where("address >>= ?", address)
    end
  end

  def self.no_account_creation(address, domain = nil)
    match(address, domain).where(:k => "no_account_creation").exists?
  end

  def self.no_note_comment(address, domain = nil)
    match(address, domain).where(:k => "no_note_comment").exists?
  end

  def self.no_trace_download(address, domain = nil)
    match(address, domain).where(:k => "no_trace_download").exists?
  end
end
