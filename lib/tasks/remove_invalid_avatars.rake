# frozen_string_literal: true

namespace :db do
  desc "Remove invalid avatars from users"
  task :remove_invalid_avatars => :environment do
    chunk_size = ENV["CHUNK_SIZE"]&.to_i || 10_000

    min_id = ENV["MIN_USER"]&.to_i || User.minimum(:id)
    max_id = ENV["MAX_USER"]&.to_i || User.maximum(:id)

    User.where(:id => min_id..max_id)
        .joins(:avatar_attachment)
        .in_batches(:of => chunk_size) do |batch|
      ids = batch.ids

      puts "Processing users #{ids.first} to #{ids.last} ..."

      batch.each do |user|
        if user.invalid? && user.errors.include?(:avatar)
          puts "Purging invalid image for user #{user.id}"
          user.avatar.purge_later
        end
      end
    end
  end
end
