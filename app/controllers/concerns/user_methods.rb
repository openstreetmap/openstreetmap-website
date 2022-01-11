module UserMethods
  extend ActiveSupport::Concern

  private

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
        user.email = user.new_email

        if user.valid?
          flash[:notice] = t "accounts.update.success_confirm_needed"

          begin
            UserMailer.email_confirm(user, user.tokens.create).deliver_later
          rescue StandardError
            # Ignore errors sending email
          end
        else
          current_user.errors.add(:new_email, current_user.errors[:email])
          current_user.errors.add(:email, [])
        end

        user.restore_email!
      end
    end
  end
end
