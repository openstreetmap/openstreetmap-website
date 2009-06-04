require 'base64'

# +SqlSessionStore+ is a stripped down, optimized for speed version of
# class +ActiveRecordStore+.

# Hack for older versions of Rails
unless defined?(ActionController::Session::AbstractStore)
  module ActionController
    module Session
      class AbstractStore
      end
    end
  end
end

class SqlSessionStore < ActionController::Session::AbstractStore

  # The class to be used for creating, retrieving and updating sessions.
  # Defaults to SqlSessionStore::SqlSession, which is derived from +ActiveRecord::Base+.
  #
  # In order to achieve acceptable performance you should implement
  # your own session class, similar to the one provided for Myqsl.
  #
  # Only functions +find_session+, +create_session+,
  # +update_session+ and +destroy+ are required. The best implementations
  # are +postgresql_session.rb+ and +oracle_session.rb+.
  cattr_accessor :session_class
  self.session_class = SqlSession

  # Rack-ism for Rails 2.3.0
  SESSION_RECORD_KEY = 'rack.session.record'.freeze

  # Backwards-compat indicators (booleans for speed)
  cattr_accessor :use_rack_session, :use_cgi_session
  self.use_rack_session = false
  self.use_cgi_session  = false

  # For Rack compatibility (Rails 2.3.0+)
  def get_session(env, sid)
    sid ||= generate_sid
    #puts "get_session(#{sid})"
    session = find_or_create_session(sid)
    env[SESSION_RECORD_KEY] = session
    [sid, session.data]
  end

  # For Rack compatibility (Rails 2.3.0+)
  def set_session(env, sid, session_data)
    #puts "set_session(#{sid})"
    session = env[SESSION_RECORD_KEY]
    session.update_session(session_data)
    return true # indicate ok to Rack
  end

  # Create a new SqlSessionStore instance. This method hooks into
  # the find/create methods of a given driver class.
  #
  # +session_id+ is the session ID for which this instance is being created.
  def find_or_create_session(session_id)
    if @session = session_class.find_session(session_id)
      @data = @session.data
    else
      @session = session_class.create_session(session_id)
      @data = {}
    end
    @session
  end

  # Below here is for pre-Rails 2.3.0 and not used in Rack-based servers
  # The CGI::Session methods are a bit odd in that half are class and half
  # are instance-based methods
  # Note that +option+ is currently ignored as no options are recognized.
  def initialize(session, options={})
    # This is just some optimization since this is called over and over and over
    if self.use_rack_session
      super # MUST call super for Rack sessions
      return true
    elsif self.use_cgi_session
      find_or_create_session(session.session_id)
    else
      version ||= Rails.version.split('.')
      if version[0].to_i == 2 && version[1].to_i < 3
        find_or_create_session(session.session_id)
        self.use_cgi_session = true
      else
        super # MUST call super for Rack sessions
        self.use_rack_session = true
      end
    end
  end

  # Update the database and disassociate the session object
  def close
    if @session
      @session.update_session(@data)
      @session = nil
    end
  end

  # Delete the current session, disassociate and destroy session object
  def delete
    if @session
      @session.destroy
      @session = nil
    end
  end

  # Restore session data from the session object
  def restore
    if @session
      @data = @session.data
    end
  end

  # Save session data in the session object
  def update
    if @session
      @session.update_session(@data)
    end
  end
  
  def id
    @session.id
  end
end

class CGI::Session
  def id
    @dbman.id
  end
end
__END__

# This software is released under the MIT license
#
# Copyright (c) 2008, 2009 Nate Wiger
# Copyright (c) 2005, 2006 Stefan Kaes

# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:

# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

