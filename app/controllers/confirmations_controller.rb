class ConfirmationsController < ApplicationController
  include SessionMethods
  include UserMethods

  layout "site"

  before_action :authorize_web
  before_action :set_locale
  before_action :check_database_readable

  authorize_resource :class => false

  before_action :check_database_writable, :only => [:confirm, :confirm_email]
  before_action :require_cookies, :only => [:confirm]

  def confirm
    if request.post?
      user = User.find_by_token_for(:new_user, params[:confirm_string])

      if !user
        flash[:error] = t(".unknown token")
        redirect_to :action => "confirm"
      elsif user.active?
        flash[:error] = t(".already active")
        redirect_to login_path
      elsif !user.visible?
        render_unknown_user user.display_name
      else
        user.activate
        user.email_valid = true
        flash[:notice] = gravatar_status_message(user) if gravatar_enable(user)
        user.save!
        cookies.delete :_osm_anonymous_notes_count
        referer = safe_referer(params[:referer]) if params[:referer]

        pending_user = session.delete(:pending_user)

        if user.id == pending_user
          session[:user] = user.id
          session[:fingerprint] = user.fingerprint

          redirect_to referer || welcome_path
        else
          flash[:notice] = t(".success")
          redirect_to login_path(:referer => referer)
        end
      end
    else
      user = User.visible.find_by(:display_name => params[:display_name])

      redirect_to root_path if user.nil? || user.active?
    end
  end

  def confirm_resend
    user = User.visible.find_by(:display_name => params[:display_name])

    if user.nil? || user.id != session[:pending_user]
      flash[:error] = t ".failure", :name => params[:display_name]
    else
      UserMailer.signup_confirm(user, user.generate_token_for(:new_user)).deliver_later
      flash[:notice] = { :partial => "confirmations/resend_success_flash", :locals => { :email => user.email, :sender => Settings.email_from } }
    end

    redirect_to login_path
  end

  def confirm_email
    if request.post?
      self.current_user = User.find_by_token_for(:new_email, params[:confirm_string])

      if current_user&.new_email?
        current_user.email = current_user.new_email
        current_user.new_email = nil
        current_user.email_valid = true
        gravatar_enabled = gravatar_enable(current_user)
        if current_user.save
          flash[:notice] = if gravatar_enabled
                             "#{t('.success')} #{gravatar_status_message(current_user)}"
                           else
                             t(".success")
                           end
        else
          flash[:errors] = current_user.errors
        end
        session[:user] = current_user.id
        session[:fingerprint] = current_user.fingerprint
      elsif current_user
        flash[:error] = t ".failure"
      else
        flash[:error] = t ".unknown_token"
      end

      redirect_to account_path
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
