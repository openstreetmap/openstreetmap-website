# frozen_string_literal: true

require "ipaddr"

class MergeAclAddressAndMask < ActiveRecord::Migration[4.2]
  class Acl < ApplicationRecord
  end

  def up
    Acl.find_each do |acl|
      address = IPAddr.new(acl.address)
      netmask = IPAddr.new(acl.netmask)
      prefix = 0

      while netmask != "0.0.0.0"
        netmask <<= 1
        prefix += 1
      end

      acl.address = "#{address.mask(prefix)}/#{prefix}"
      acl.save!
    end

    remove_column :acls, :netmask
  end

  def down
    add_column :acls, :netmask, :inet

    Acl.find_each do |acl|
      address = IPAddr.new(acl.address)

      acl.address = address.to_string
      acl.netmask = address.netmask
      acl.save!
    end

    change_column :acls, :netmask, :inet, :null => false
  end
end
