#!/usr/bin/env ruby

#You might want to change this
#ENV["RAILS_ENV"] ||= "development"

require File.dirname(__FILE__) + "/../../config/environment"

require 'pstore'

terminated = false

session_path = ActionController::Base.session_options[:tmpdir]

def expire_session(name)
  ActiveRecord::Base.logger.info("Expiring session #{File.basename(name)}")
  FileUtils.rm_f(name)
end

while (true) do
  Dir.foreach(session_path) do |session_name|
    if session_name =~ /^ruby_sess\./
      session_name = session_path + "/" + session_name
      session = PStore.new(session_name)

      session.transaction do |session|
        session_hash = session['hash']

        if session_hash
          session_stat = File::Stat.new(session_name)
            puts session_hash[:token]

          if session_hash[:token] and User.find_by_token(session_hash[:token])
#            expire_session(session_name) if session_stat.mtime < 1.day.ago
          else
            expire_session(session_name) if session_stat.mtime < 1.hour.ago
          end
        else
          expire_session(session_name)
        end
      end
    end
  end

  sleep 15.minutes
end
