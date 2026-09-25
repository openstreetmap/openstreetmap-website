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
          user = find_by("email = ? OR display_name = ?", username.strip, username)

          if user.nil?
            users = where("LOWER(email) = LOWER(?) OR LOWER(NORMALIZE(display_name, NFKC)) = LOWER(NORMALIZE(?, NFKC))", username.strip, username)

            user = users.first if users.one?
          end

          user if user && user.status != "deleted"
        end
      end


      def valid_password?(password)
        is_valid =
          if Argon2::HashFormat.valid_hash?(encrypted_password)
            Argon2::Password.verify_password(password, encrypted_password)
          elsif salt&.include?("!")
            algorithm, iterations, actual_salt = salt.split("!")
            size = Base64.strict_decode64(encrypted_password).length
            ActiveSupport::SecurityUtils.secure_compare(encrypted_password, Functions.pbkdf2(password, actual_salt, iterations.to_i, size, algorithm))
          end

        upgrade_password(password) if is_valid && Functions.needs_upgrade?(encrypted_password)

        is_valid
      end

      def upgrade_password(password)
        self.encrypted_password = Argon2::Password.create(password)
        self.salt = nil
        save
      end

      module Functions
        def self.needs_upgrade?(encrypted_password)
          format = Argon2::HashFormat.new(encrypted_password)

          format.variant != FORMAT.variant ||
            format.version != FORMAT.version ||
            format.t_cost != FORMAT.t_cost ||
            format.m_cost != FORMAT.m_cost ||
            format.p_cost != FORMAT.p_cost
        rescue Argon2::ArgonHashFail
          true
        end

        def self.pbkdf2(password, salt, iterations, size, algorithm)
          digest = OpenSSL::Digest.new(algorithm)
          pbkdf2 = OpenSSL::PKCS5.pbkdf2_hmac(password, salt, iterations, size, digest)
          Base64.strict_encode64(pbkdf2)
        end
      end

      module ClassMethods
        Devise::Models.config(self, :osm_argon2_options)
      end
    end
  end
end
