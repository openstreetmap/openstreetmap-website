# frozen_string_literal: true

module Devise
  module Strategies
    class OsmAuthenticatable < DatabaseAuthenticatable
      private

      def params
        { :user => request.params.slice(:username, :password) }
      end

      def validate(resource)
        if resource&.password_expired?
          # Warden has a method called `fail`, different from the
          # alias for `raise`. We tell Rubocop or it'll complain.
          #
          # rubocop:disable-next Style/SignalException
          fail(:password_expired)

          # For the same reason as above, Rubocop thinks that this
          # code is unreachable, which is incorrect.
          #
          # rubocop:disable-next Lint/UnreachableCode
          false
        else
          super && check_resource_status!(resource)
        end
      end

      def check_resource_status!(resource)
        if resource.active?
          true
        elsif resource.pending?
          # TODO: session[:pending_user] = user.id
          # TODO: session.delete(:remember_me)
          redirect!(
            Rails.application.routes.url_helpers.url_for(
              :controller => "confirmations",
              :action => "confirm",
              :display_name => resource.display_name,
              :only_path => true
              # TODO: :referer => referer
            )
          )
          false
        else
          fail!(
            :code => :user_suspended,
            :username => resource.display_name,
            :referer => params[:referer]
          )
          false
        end
      end
    end
  end
end

Warden::Strategies.add(:osm_authenticatable, Devise::Strategies::OsmAuthenticatable)
