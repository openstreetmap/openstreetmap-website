FactoryBot.define do
  factory :note_comment do
    sequence(:body) { |n| "This is note comment #{n}" }
    visible { true }
    note

    # Define transient attribute for additional comments
    transient do
      event { "commented" }
    end

    after(:create) do |note_comment, evaluator|
      # Calculate the next version number based on existing `note_versions` for the note
      next_version_number = note_comment.note.note_versions.maximum(:version).to_i + 1

      # Create new note version
      create(:note_version, :note => note_comment.note, :note_comment_id => note_comment.id, :event => evaluator.event, :version => next_version_number) if evaluator.event != "commented"

      # Update note's version
      note_comment.note.update(:version => next_version_number) if evaluator.event != "commented"
    end
  end
end
