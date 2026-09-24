# frozen_string_literal: true

require "devise/models/database_authenticatable"
require "devise/strategies/osm_authenticatable"

module Devise
  module Models
    module OsmAuthenticatable
      extend ActiveSupport::Concern
      include DatabaseAuthenticatable

      alias_attribute :encrypted_password, :pass_crypt
      alias_attribute :salt, :pass_salt

      attr_writer :username

      def username
        @username || email || display_name
      end
    end
  end
end
