# frozen_string_literal: true

require "devise/models/database_authenticatable"

module Devise
  module Strategies
    class OsmAuthenticatable < DatabaseAuthenticatable
      def authenticate!
        resource = password.present? && mapping.to.find_for_database_authentication(authentication_hash)
        hashed = false

        if resource.nil?
          fail!(
            :code => Devise.paranoid ? :invalid : :not_found_in_database,
            :username => params.dig(:user, :username),
            :referer => params[:referer]
          )
          return
        elsif resource.password_expired?
          fail!(:password_expired)
          return
        end

        if validate(resource) do
          hashed = true
          resource.valid_password?(password)
        end
          remember_me(resource)
          resource.after_database_authentication
          success!(resource)
        end

        # In paranoid mode, hash the password even when a resource doesn't exist for the given authentication key.
        # This is necessary to prevent enumeration attacks - e.g. the request is faster when a resource doesn't
        # exist in the database if the password hashing algorithm is not called.
        mapping.to.new.password = password if !hashed && Devise.paranoid
        unless resource
          # Warden defines its own `fail` method, different
          # from the usual one that aliases `raise`.
          # rubocop:disable-next Style/SignalException
          Devise.paranoid ? fail(:invalid) : fail(:not_found_in_database)
        end
      end

      private

      def params
        { :user => request.params.slice(:username, :password) }
      end

      def validate(resource)
        if resource
          super && check_resource_status!(resource)
        else
          fail!(
            :code => :unknown_user,
            :username => params.dig(:user, :username),
            :referer => params[:referer]
          )
          false
        end
      end

      def check_resource_status!(resource)
        if resource.active?
          true
        elsif resource.pending?
          # TODO: session[:pending_user] = user.id
          # TODO: session.delete(:remember_me)
          redirect!(
            Rails.application.routes.url_helpers.user_confirm_by_name_path(resource.display_name)
            # TODO
            # :referer => referer
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
