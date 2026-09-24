# frozen_string_literal: true

require "devise/strategies/osm_authenticatable"

# Lifted from https://github.com/erdostom/devise-argon2
module Devise
  module Models
    module OsmAuthenticatable
      extend ActiveSupport::Concern
      include DatabaseAuthenticatable

      FORMAT = Argon2::HashFormat.new(Argon2::Password.create(""))

      included do
        def self.find_for_database_authentication(warden_conditions)
          username = warden_conditions[:username]
          user = find_by("email = ? OR display_name = ?", username.strip, username.strip)

          if user.nil?
            users = where("LOWER(email) = LOWER(?) OR LOWER(NORMALIZE(display_name, NFKC)) = LOWER(NORMALIZE(?, NFKC))", username.strip, username.strip)

            user = users.first if users.one?
          end

          user if user && user.status != "deleted"
        end
      end

      def valid_password?(password)
        if PasswordHash.check(pass_crypt, pass_salt, password)
          if PasswordHash.upgrade?(pass_crypt, pass_salt)
            self.pass_crypt, self.pass_salt = PasswordHash.create(password)
            save
          end

          true
        else
          false
        end
      end

      def password_expired?
        !PasswordHash.valid?(pass_crypt, pass_salt)
      end
    end
  end
end
