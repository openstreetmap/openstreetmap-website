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
    redirect_to oauth_clients_url(:display_name => @token.user.display_name)
  end

protected

  def oauth1_authorize
    unless @token
      render :action=>"authorize_failure"
      return
    end

    unless @token.invalidated?
      if request.post?
        if user_authorizes_token?
          @token.authorize!(current_user)
          if @token.oauth10?
            callback_url = params[:oauth_callback] || @token.client_application.callback_url
          else
            callback_url = @token.oob? ? @token.client_application.callback_url : @token.callback_url
          end
          @redirect_url = URI.parse(callback_url) unless callback_url.blank?

          unless @redirect_url.to_s.blank?
            @redirect_url.query = @redirect_url.query.blank? ?
            "oauth_token=#{@token.token}" :
              @redirect_url.query + "&oauth_token=#{@token.token}"
            unless @token.oauth10?
              @redirect_url.query += "&oauth_verifier=#{@token.verifier}"
            end
            redirect_to @redirect_url.to_s
          else
            render :action => "authorize_success"
          end
        else
          @token.invalidate!
          render :action => "authorize_failure"
        end
      end
    else
      render :action => "authorize_failure"
    end
  end
end
