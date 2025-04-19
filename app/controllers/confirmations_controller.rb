class ConfirmationsController < ApplicationController
  include SessionMethods
  include UserMethods

  layout "site"

  before_action :authorize_web
  before_action :set_locale
  before_action :check_database_readable

  authorize_resource :class => false

  before_action :check_database_writable, :only => [:new, :show, :create]
  before_action :require_cookies, :only => [:show]

  def show
    if params[:confirm_string]
      user = User.lookup_by_confirmation_token(params[:confirm_string])

      if !user
        flash[:error] = t(".unknown token")
        redirect_to root_path
      elsif !user.account_unconfirmed?
        flash[:error] = t(".failure")
        redirect_to root_path
      elsif !user.visible?
        render_unknown_user user.display_name
      else
        user.confirm_account

        gravatar_enabled = user.gravatar_enable

        referer = safe_referer(params[:referer]) if params[:referer]

        pending_user = session.delete(:pending_user)

        unless pending_user && user.id != pending_user
          cookies.delete :_osm_anonymous_notes_count
          session[:user] = user.id
          session[:fingerprint] = user.fingerprint
        end

        if user.errors.any?
          flash[:errors] = user.errors
        else
          flash[:notice] = if gravatar_enabled
                             "#{t('.success')} #{gravatar_status_message(user)}"
                           else
                             t(".success")
                           end
        end

        redirect_to referer || root_path
      end
    else
      head :bad_request
    end
  end

  def new
    user = User.visible.find_by(:display_name => params[:display_name])

    redirect_to root_path if user.nil? || user.active?
  end

  def create
    user = User.visible.find_by(:display_name => params[:display_name])

    if user.nil? || (session[:pending_user] && user.id != session[:pending_user])
      flash[:error] = t ".failure", :name => params[:display_name]
    else
      UserMailer.signup_confirm(user, user.generate_token_for(:account_confirmation), welcome_path).deliver_later
      flash[:notice] = { :partial => "confirmations/resend_success_flash", :locals => { :email => user.email, :sender => Settings.email_from } }
    end

    redirect_to new_confirmations_path
  end

  private

  ##
  # display a message about the current status of the Gravatar setting
  def gravatar_status_message(user)
    if user.image_use_gravatar
      t "profiles.edit.gravatar.enabled"
    else
      t "profiles.edit.gravatar.disabled"
    end
  end
end
