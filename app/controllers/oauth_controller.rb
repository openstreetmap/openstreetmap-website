require "oauth/controllers/provider_controller"

class OauthController < ApplicationController
  include OAuth::Controllers::ProviderController

  layout "site"

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
    @token = current_user.oauth_tokens.find_by :token => params[:token]
    if @token
      @token.invalidate!
      flash[:notice] = t("oauth.revoke.flash", :application => @token.client_application.name)
    end
    redirect_to oauth_clients_url(:display_name => @token.user.display_name)
  end

  protected

  def oauth1_authorize
    if @token.invalidated?
      @message = t "oauth.oauthorize_failure.invalid"
      render :action => "authorize_failure"
    elsif request.post?
      if user_authorizes_token?
        @token.authorize!(current_user)
        callback_url = if @token.oauth10?
                         params[:oauth_callback] || @token.client_application.callback_url
                       else
                         @token.oob? ? @token.client_application.callback_url : @token.callback_url
                       end
        @redirect_url = URI.parse(callback_url) if callback_url.present?

        if @redirect_url.to_s.blank?
          render :action => "authorize_success"
        else
          @redirect_url.query = if @redirect_url.query.blank?
                                  "oauth_token=#{@token.token}"
                                else
                                  @redirect_url.query +
                                    "&oauth_token=#{@token.token}"
                                end

          unless @token.oauth10?
            @redirect_url.query += "&oauth_verifier=#{@token.verifier}"
          end

          redirect_to @redirect_url.to_s
        end
      else
        @token.invalidate!
        @message = t("oauth.oauthorize_failure.denied", :app_name => @token.client_application.name)
        render :action => "authorize_failure"
      end
    end
  end
end
