class ConfirmationsController < ApplicationController
  include SessionMethods

  layout "site"

  before_action :authorize_web
  before_action :set_locale
  before_action :check_database_readable

  authorize_resource :class => false

  before_action :check_database_writable, :only => [:confirm, :confirm_email]
  before_action :require_cookies, :only => [:confirm]

  def confirm
    if request.post?
      token = UserToken.find_by(:token => params[:confirm_string])
      if token&.user&.active?
        flash[:error] = t("confirmations.confirm.already active")
        redirect_to login_path
      elsif !token || token.expired?
        flash[:error] = t("confirmations.confirm.unknown token")
        redirect_to :action => "confirm"
      elsif !token.user.visible?
        render_unknown_user token.user.display_name
      else
        user = token.user
        user.activate
        user.email_valid = true
        flash[:notice] = gravatar_status_message(user) if gravatar_enable(user)
        user.save!
        referer = safe_referer(token.referer) if token.referer
        token.destroy

        if session[:token]
          token = UserToken.find_by(:token => session[:token])
          session.delete(:token)
        else
          token = nil
        end

        if token.nil? || token.user != user
          flash[:notice] = t("confirmations.confirm.success")
          redirect_to login_path(:referer => referer)
        else
          token.destroy

          session[:user] = user.id
          session[:fingerprint] = user.fingerprint

          redirect_to referer || welcome_path
        end
      end
    else
      user = User.visible.find_by(:display_name => params[:display_name])

      redirect_to root_path if user.nil? || user.active?
    end
  end

  def confirm_resend
    user = User.visible.find_by(:display_name => params[:display_name])
    token = UserToken.find_by(:token => session[:token])

    if user.nil? || token.nil? || token.user != user
      flash[:error] = t "confirmations.confirm_resend.failure", :name => params[:display_name]
    else
      UserMailer.signup_confirm(user, user.tokens.create).deliver_later
      flash[:notice] = { :partial => "confirmations/resend_success_flash", :locals => { :email => user.email, :sender => Settings.email_from } }
    end

    redirect_to login_path
  end

  def confirm_email
    if request.post?
      token = UserToken.find_by(:token => params[:confirm_string])
      if token&.user&.new_email?
        self.current_user = token.user
        current_user.email = current_user.new_email
        current_user.new_email = nil
        current_user.email_valid = true
        gravatar_enabled = gravatar_enable(current_user)
        if current_user.save
          flash[:notice] = if gravatar_enabled
                             "#{t('confirmations.confirm_email.success')} #{gravatar_status_message(current_user)}"
                           else
                             t("confirmations.confirm_email.success")
                           end
        else
          flash[:errors] = current_user.errors
        end
        current_user.tokens.delete_all
        session[:user] = current_user.id
        session[:fingerprint] = current_user.fingerprint
        redirect_to edit_account_path
      elsif token
        flash[:error] = t "confirmations.confirm_email.failure"
        redirect_to edit_account_path
      else
        flash[:error] = t "confirmations.confirm_email.unknown_token"
      end
    end
  end

  private

  ##
  # check if this user has a gravatar and set the user pref is true
  def gravatar_enable(user)
    # code from example https://en.gravatar.com/site/implement/images/ruby/
    return false if user.avatar.attached?

    begin
      hash = Digest::MD5.hexdigest(user.email.downcase)
      url = "https://www.gravatar.com/avatar/#{hash}?d=404" # without d=404 we will always get an image back
      response = OSM.http_client.get(URI.parse(url))
      available = response.success?
    rescue StandardError
      available = false
    end

    oldsetting = user.image_use_gravatar
    user.image_use_gravatar = available
    oldsetting != user.image_use_gravatar
  end

  ##
  # display a message about th current status of the gravatar setting
  def gravatar_status_message(user)
    if user.image_use_gravatar
      t "profiles.edit.gravatar.enabled"
    else
      t "profiles.edit.gravatar.disabled"
    end
  end
end
