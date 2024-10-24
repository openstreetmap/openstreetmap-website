module Api
  class NoteSubscriptionsController < ApiController
    before_action :check_api_writable
    before_action :authorize

    authorize_resource

    def create
      note_id = params[:note_id].to_i
      note = Note.find(note_id)
      note.subscribers << current_user
    rescue ActiveRecord::RecordNotFound
      report_error "Note #{note_id} not found.", :not_found
    rescue ActiveRecord::RecordNotUnique
      report_error "You are already subscribed to note #{note_id}.", :conflict
    end

    def destroy
      note_id = params[:note_id].to_i
      note = Note.find(note_id)
      count = note.subscriptions.where(:user => current_user).delete_all
      report_error "You are not subscribed to note #{note_id}.", :not_found if count.zero?
    rescue ActiveRecord::RecordNotFound
      report_error "Note #{note_id} not found.", :not_found
    end
  end
end
