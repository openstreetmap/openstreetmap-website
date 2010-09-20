class OauthController < ApplicationController
  layout 'site'

  before_filter :authorize_web, :only => [:oauthorize, :revoke]
  before_filter :set_locale, :only => [:oauthorize, :revoke]
  before_filter :require_user, :only => [:oauthorize]
  before_filter :verify_oauth_consumer_signature, :only => [:request_token]
  before_filter :verify_oauth_request_token, :only => [:access_token]
  # Uncomment the following if you are using restful_open_id_authentication
  # skip_before_filter :verify_authenticity_token

  def request_token
    @token = current_client_application.create_request_token

    if @token
      logger.info "request token params: #{params.inspect}"
      # request tokens indicate what permissions the client *wants*, not
      # necessarily the same as those which the user allows.
      current_client_application.permissions.each do |pref|
        @token.write_attribute(pref, true)
      end
      @token.save!

      render :text => @token.to_query
    else
      render :nothing => true, :status => 401
    end
  end

  def access_token
    @token = current_token && current_token.exchange!
    if @token
      render :text => @token.to_query
    else
      render :nothing => true, :status => 401
    end
  end

  def oauthorize
    @token = RequestToken.find_by_token params[:oauth_token]
    unless @token.nil? or @token.invalidated? 
      if request.post?
        any_auth = false
        @token.client_application.permissions.each do |pref|
          if params[pref]
            @token.write_attribute(pref, true)
            any_auth ||= true
          else
            @token.write_attribute(pref, false)
          end
        end

        if any_auth
          @token.authorize!(@user)
          if @token.oauth10?
            redirect_url = params[:oauth_callback] || @token.client_application.callback_url
          else
            redirect_url = @token.oob? ? @token.client_application.callback_url : @token.callback_url
          end
          if redirect_url and not redirect_url.empty?
            if @token.oauth10?
              redirect_to "#{redirect_url}?oauth_token=#{@token.token}"
            else
              redirect_to "#{redirect_url}?oauth_token=#{@token.token}&oauth_verifier=#{@token.verifier}"
            end
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

  def revoke
    @token = @user.oauth_tokens.find_by_token params[:token]
    if @token
      @token.invalidate!
      flash[:notice] = t('oauth.revoke.flash', :application => @token.client_application.name)
    end
    redirect_to :controller => 'oauth_clients', :action => 'index'
  end
end
