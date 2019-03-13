class OauthController < ApplicationController
  include OAuth::Controllers::ProviderController

  # The ProviderController will call login_required for any action that needs
  # a login, but we want to check authorization on every action.
  authorize_resource :class => false

  layout "site"

  def revoke
    @token = current_user.oauth_tokens.find_by :token => params[:token]
    if @token
      @token.invalidate!
      flash[:notice] = t(".flash", :application => @token.client_application.name)
    end
    redirect_to oauth_clients_url(:display_name => @token.user.display_name)
  end

  protected

  def login_required
    authorize_web
    set_locale
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

  def oauth1_authorize
    override_content_security_policy_directives(:form_action => []) if Settings.csp_enforce || Settings.key?(:csp_report_url)

    if @token.invalidated?
      @message = t "oauth.authorize_failure.invalid"
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

          @redirect_url.query += "&oauth_verifier=#{@token.verifier}" unless @token.oauth10?

          redirect_to @redirect_url.to_s
        end
      else
        @token.invalidate!
        @message = t("oauth.authorize_failure.denied", :app_name => @token.client_application.name)
        render :action => "authorize_failure"
      end
    end
  end
end
