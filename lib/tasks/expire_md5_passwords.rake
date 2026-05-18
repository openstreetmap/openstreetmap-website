# frozen_string_literal: true

namespace :db do
  desc "Expire MD5 passwords"
  task :expire_md5_passwords => :environment do
    chunk_size = ENV["CHUNK_SIZE"]&.to_i || 10_000

    User
      .where("pass_crypt SIMILAR TO '[0-9a-z]{32}'")
      .in_batches(:of => chunk_size)
      .update_all(:pass_crypt => "expired password", :pass_salt => nil)
  end
end
