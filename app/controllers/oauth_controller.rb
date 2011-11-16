require 'oauth/controllers/provider_controller'

class OauthController < ApplicationController
  include OAuth::Controllers::ProviderController

  layout 'slim'

  def login_required
    authorize_web
    set_locale
    require_user
  end

  def user_authorizes_token?
    any_auth = false

    @token.client_application.permissions.each do |pref|
      if params[pref]
        @token.write_attribute(pref, true)
        any_auth ||= true
      else
        @token.write_attribute(pref, false)
      end
    end

    any_auth
  end

  def revoke
    @token = current_user.oauth_tokens.find_by_token params[:token]
    if @token
      @token.invalidate!
      flash[:notice] = t('oauth.revoke.flash', :application => @token.client_application.name)
    end
    redirect_to :controller => 'oauth_clients', :action => 'index'
  end
end
