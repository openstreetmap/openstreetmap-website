# frozen_string_literal: true

namespace :db do
  desc "Remove avatars with unsupported content types from users"
  task :remove_unsupported_avatars => :environment do
    User.joins(:avatar_blob)
        .where.not(:active_storage_blobs => { :content_type => User::AVATAR_CONTENT_TYPES })
        .includes(:avatar_attachment => :blob)
        .find_each do |user|
      puts "Purging #{user.avatar.content_type} image for user #{user.id}"
      user.avatar.purge_later
    end
  end
end
