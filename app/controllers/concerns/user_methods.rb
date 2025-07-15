module UserMethods
  extend ActiveSupport::Concern

  private

  ##
  # ensure that there is a "user" instance variable
  def lookup_user
    display_name = params[:display_name] || params[:user_display_name]
    @user = User.active.find_by!(:display_name => display_name)
  rescue ActiveRecord::RecordNotFound
    render_unknown_user display_name
  end

  ##
  # render a "no such user" page
  def render_unknown_user(name)
    @title = t "users.no_such_user.title"
    @not_found_user = name

    respond_to do |format|
      format.html { render :template => "users/no_such_user", :status => :not_found, :layout => "site" }
      format.all { head :not_found }
    end
  end

  ##
  # update a user's details
  def update_user(user, params)
    user.display_name = params[:display_name]
    user.new_email = params[:new_email]

    unless params[:pass_crypt].empty? && params[:pass_crypt_confirmation].empty?
      user.pass_crypt = params[:pass_crypt]
      user.pass_crypt_confirmation = params[:pass_crypt_confirmation]
    end

    if params[:auth_provider].nil? || params[:auth_provider].blank?
      user.auth_provider = nil
      user.auth_uid = nil
    end

    if user.save
      session[:fingerprint] = user.fingerprint

      if user.new_email.blank? || user.new_email == user.email
        flash[:notice] = t "accounts.update.success"
      else
        token = user.generate_token_for(:new_email)

        user.email = user.new_email

        if user.valid?
          flash[:notice] = t "accounts.update.success_confirm_needed"

          begin
            UserMailer.email_confirm(user, token).deliver_later
          rescue StandardError
            # Ignore errors sending email
          end
        else
          current_user.errors.delete(:email).each do |error|
            current_user.errors.add(:new_email, error)
          end
        end

        user.restore_email!
      end
    end
  end
end
