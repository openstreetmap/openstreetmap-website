namespace "storage" do
  task :upgrade_avatars => :environment do
    User.active.where.not(:image_file_name => nil).in_batches.each_record do |user|
      next if user.avatar.attached?

      io = File.open(user.image.path)
      filename = user.image.original_filename
      content_type = if user.image.content_type.nil?
                       MimeMagic.by_magic(io)&.type
                     else
                       user.image.content_type
                     end

      user.avatar.attach(:io => io, :filename => filename, :content_type => content_type)
    end
  end
end
