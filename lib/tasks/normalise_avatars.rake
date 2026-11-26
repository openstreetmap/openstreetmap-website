# frozen_string_literal: true

namespace :db do
  desc "Normalise avatars uploaded before BEFORE (an ISO 8601 time), replacing the originals"
  task :normalise_avatars => :environment do
    abort "Set BEFORE to the ISO 8601 time when upload normalisation was deployed, e.g. BEFORE=2026-11-20T00:00:00Z" unless ENV["BEFORE"]

    before = Time.zone.iso8601(ENV.fetch("BEFORE"))

    User.joins(:avatar_blob)
        .where(:active_storage_blobs => { :content_type => User::AVATAR_CONTENT_TYPES })
        .where(:active_storage_blobs => { :created_at => ...before })
        .find_each do |user|
      user.with_lock do
        blob = user.avatar.blob
        # Skip if the user uploaded a new avatar since we selected them
        next if blob.created_at >= before

        blob.open do |file|
          user.avatar = { :io => file, :filename => blob.filename.to_s, :content_type => blob.content_type }
          # Skip validation, as old users and avatars may not pass current checks
          if user.save(:validate => false)
            puts "Normalised #{blob.content_type} avatar for user #{user.id}"
          else
            puts "Failed to normalise #{blob.content_type} avatar for user #{user.id}: #{user.errors.full_messages.to_sentence}"
          end
        end
      end
    rescue ActiveStorage::FileNotFoundError
      puts "Missing avatar file for user #{user.id}"
    end
  end
end
