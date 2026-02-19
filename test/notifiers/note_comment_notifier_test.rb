# frozen_string_literal: true

require "test_helper"

class NoteCommentNotifierTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper
  include ActiveJob::TestHelper

  test "delivers to all subscribers except the author" do
    author = create(:user)
    commenter1 = create(:user)
    commenter2 = create(:user)
    _non_commenter = create(:user)

    note = create(:note, :author => author)
    create(:note_subscription, :note => note, :user => author)
    _comment1 = create(:note_comment, :note => note, :author => commenter1)
    create(:note_subscription, :note => note, :user => commenter1)
    comment2 = create(:note_comment, :note => note, :author => commenter2)
    create(:note_subscription, :note => note, :user => commenter2)

    NoteCommentNotifier.with(:record => comment2).deliver_later

    perform_enqueued_jobs
    Nominatim.stub(:describe_location, nil) do
      perform_enqueued_jobs
    end

    recipient_addresses = Mail::TestMailer.deliveries.map(&:to).flatten
    assert_equal [author.email, commenter1.email].sort, recipient_addresses.sort
  end
end
