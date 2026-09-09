# frozen_string_literal: true

module AclsHelper
  # Format an IPAddr the way PostgreSQL's inet type does: host addresses
  # are shown bare, while networks carry their prefix length.
  def acl_address(address)
    return nil if address.nil?

    host_prefix = address.ipv4? ? 32 : 128

    if address.prefix == host_prefix
      address.to_s
    else
      "#{address}/#{address.prefix}"
    end
  end
end
