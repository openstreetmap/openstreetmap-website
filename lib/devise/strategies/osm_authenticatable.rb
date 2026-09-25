require "devise/models/database_authenticatable"

module Devise
  module Strategies
    class OsmAuthenticatable < DatabaseAuthenticatable

      private

      def validate(resource)
        super && check_resource_status!(resource)
      end

      def check_resource_status!(resource)
        if resource.active?
          true
        elsif resource.pending?
          # TODO: session[:pending_user] = user.id
          # TODO: session.delete(:remember_me)
          redirect!(
            Rails.application.routes.url_helpers.user_confirm_path(resource.display_name)
            # TODO
            # :referer => referer
          )
          false
        else
          fail!("You are suspended")
          false
        end
      end
    end
  end
end

Warden::Strategies.add(:osm_authenticatable, Devise::Strategies::OsmAuthenticatable)
