# frozen_string_literal: true

require "test_helper"

class NormaliseAvatarsTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def setup
    Rails.application.load_tasks if Rake::Task.tasks.empty?
    Rake::Task["db:normalise_avatars"].reenable
  end

  def test_normalises_old_avatar
    image = Vips::Image.black(1000, 600, :bands => 3).copy
    image.set_type(GObject::GSTR_TYPE, "exif-ifd0-ImageDescription", "Somewhere secret")
    user = create(:user)
    original = attach_unnormalised(user, image.write_to_buffer(".jpg"), "IMG_1234.jpg", Time.utc(2026, 11, 19))

    run_task("2026-11-20T00:00:00Z")

    user.reload
    assert_not_equal original.id, user.avatar.blob.id
    assert_equal "avatar.jpg", user.avatar.filename.to_s
    stored = Vips::Image.new_from_buffer(user.avatar.blob.download, "")
    assert_empty stored.get_fields.grep(/exif/)
    assert_equal [512, 307], [stored.width, stored.height]
    assert_not ActiveStorage::Blob.exists?(original.id), "should purge the original"
  end

  def test_skips_avatar_uploaded_after_cutoff
    user = create(:user)
    blob = attach_unnormalised(user, Vips::Image.black(10, 10).write_to_buffer(".png"), "photo.png", Time.utc(2026, 11, 21))

    run_task("2026-11-20T00:00:00Z")

    assert_equal blob.id, user.reload.avatar.blob.id
  end

  def test_skips_unsupported_type
    user = create(:user)
    blob = attach_unnormalised(user, '<svg xmlns="http://www.w3.org/2000/svg" width="1" height="1"/>', "photo.svg", Time.utc(2026, 11, 19))

    output = run_task("2026-11-20T00:00:00Z")

    assert_equal blob.id, user.reload.avatar.blob.id
    assert_no_match "user #{user.id}", output, "should not try to normalise it"
  end

  def test_normalises_avatar_over_current_file_size_limit
    user = create(:user)
    original = attach_unnormalised(user, Vips::Image.black(1000, 1000).write_to_buffer(".png"), "photo.png", Time.utc(2026, 11, 19))

    with_settings(:max_avatar_size => original.byte_size - 1) do
      run_task("2026-11-20T00:00:00Z")
    end

    assert_not_equal original.id, user.reload.avatar.blob.id
  end

  def test_continues_after_failure
    broken_user = create(:user)
    broken = attach_unnormalised(broken_user, "not an image", "broken.png", Time.utc(2026, 11, 19), :content_type => "image/png")
    user = create(:user)
    original = attach_unnormalised(user, Vips::Image.black(10, 10).write_to_buffer(".png"), "photo.png", Time.utc(2026, 11, 19))

    output = run_task("2026-11-20T00:00:00Z")

    assert_match "Failed to normalise image/png avatar for user #{broken_user.id}", output
    assert_equal broken.id, broken_user.reload.avatar.blob.id, "should keep the avatar that failed"
    assert_not_equal original.id, user.reload.avatar.blob.id
  end

  def test_requires_cutoff
    assert_raises(SystemExit) { run_task(nil) }
  end

  private

  # Attach an avatar directly, bypassing the upload normalisation
  def attach_unnormalised(user, data, filename, created_at, content_type: nil)
    blob = ActiveStorage::Blob.create_and_upload!(:io => StringIO.new(data), :filename => filename, :content_type => content_type, :identify => content_type.nil?)
    blob.update!(:created_at => created_at)
    ActiveStorage::Attachment.create!(:name => "avatar", :record => user, :blob => blob)
    blob
  end

  def run_task(before)
    with_env("BEFORE" => before) do
      perform_enqueued_jobs do
        capture_io { Rake::Task["db:normalise_avatars"].invoke }.first
      end
    end
  end

  def with_env(vars)
    saved = vars.keys.index_with { |k| ENV.fetch(k, nil) }
    vars.each { |k, v| ENV[k] = v }
    yield
  ensure
    saved.each { |k, v| ENV[k] = v }
  end
end
