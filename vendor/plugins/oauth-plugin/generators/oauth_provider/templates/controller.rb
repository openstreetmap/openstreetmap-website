class OauthController < ApplicationController
  before_filter :login_required, :except => [:request_token, :access_token, :test_request]
  before_filter :login_or_oauth_required, :only => [:test_request]
  before_filter :verify_oauth_consumer_signature, :only => [:request_token]
  before_filter :verify_oauth_request_token, :only => [:access_token]
  # Uncomment the following if you are using restful_open_id_authentication
  # skip_before_filter :verify_authenticity_token

  def request_token
    @token = current_client_application.create_request_token
    if @token
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

  def test_request
    render :text => params.collect{|k,v|"#{k}=#{v}"}.join("&")
  end
  
  def authorize
    @token = RequestToken.find_by_token params[:oauth_token]
    unless @token.invalidated?    
      if request.post? 
        if params[:authorize] == '1'
          @token.authorize!(current_user)
          redirect_url = params[:oauth_callback] || @token.client_application.callback_url
          if redirect_url
            redirect_to "#{redirect_url}?oauth_token=#{@token.token}"
          else
            render :action => "authorize_success"
          end
        elsif params[:authorize] == "0"
          @token.invalidate!
          render :action => "authorize_failure"
        end
      end
    else
      render :action => "authorize_failure"
    end
  end
  
  def revoke
    @token = current_user.tokens.find_by_token params[:token]
    if @token
      @token.invalidate!
      flash[:notice] = "You've revoked the token for #{@token.client_application.name}"
    end
    redirect_to oauth_clients_url
  end
  
end
