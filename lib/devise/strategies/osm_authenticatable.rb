require "devise/models/database_authenticatable"

module Devise
  module Strategies
    class OsmAuthenticatable < DatabaseAuthenticatable

      private

      def validate(resource)
        pp "VALIDATE!"
        super && check_resource_status!(resource)
      end

      def check_resource_status!(resource)
        if resource.active?
          true
        else
          fail!("You are suspended")
          false
        end
      end
    end
  end
end

Warden::Strategies.add(:osm_authenticatable, Devise::Strategies::OsmAuthenticatable)
