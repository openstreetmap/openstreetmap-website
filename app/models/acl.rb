# == Schema Information
#
# Table name: acls
#
#  id      :bigint(8)        not null, primary key
#  address :inet
#  k       :string           not null
#  v       :string
#  domain  :string
#  mx      :string
#
# Indexes
#
#  acls_k_idx             (k)
#  index_acls_on_address  (address) USING gist
#  index_acls_on_domain   (domain)
#  index_acls_on_mx       (mx)
#

class Acl < ApplicationRecord
  validates :k, :presence => true

  def self.match(address, options = {})
    acls = Acl.where("address >>= ?", address)

    acls = acls.or(Acl.where(:domain => options[:domain])) if options[:domain]
    acls = acls.or(Acl.where(:mx => options[:mx])) if options[:mx]

    acls
  end

  def self.no_account_creation(address, options = {})
    match(address, options).exists?(:k => "no_account_creation")
  end

  def self.no_note_comment(address, domain = nil)
    match(address, :domain => domain).exists?(:k => "no_note_comment")
  end

  def self.no_trace_download(address, domain = nil)
    match(address, :domain => domain).exists?(:k => "no_trace_download")
  end
end
