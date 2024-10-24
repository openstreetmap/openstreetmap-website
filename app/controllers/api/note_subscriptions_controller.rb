module Api
  class NoteSubscriptionsController < ApiController
    before_action :check_api_writable
    before_action :authorize

    authorize_resource

    def create
      note_id = params[:note_id].to_i
      note = Note.find(note_id)
      note.subscribers << current_user
    rescue ActiveRecord::RecordNotUnique
      head :conflict
    end

    def destroy
      note_id = params[:note_id].to_i
      count = NoteSubscription.where(:user => current_user, :note => note_id).delete_all
      head :not_found if count.zero?
    end
  end
end
