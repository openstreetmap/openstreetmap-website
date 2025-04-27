# frozen_string_literal: true

class UseMicrosoftGraph < ActiveRecord::Migration[7.0]
  def self.up
    User.where(:auth_provider => "windowslive").update_all(:auth_provider => "microsoft")
  end

  def self.down
    User.where(:auth_provider => "microsoft").update_all(:auth_provider => "windowslive")
  end
end
