require 'active_record'
require 'cgi'
require 'cgi/session'
begin
  require 'base64'
rescue LoadError
end

# +SqlSessionStore+ is a stripped down, optimized for speed version of
# class +ActiveRecordStore+.

class SqlSessionStore

  # The class to be used for creating, retrieving and updating sessions.
  # Defaults to SqlSessionStore::Session, which is derived from +ActiveRecord::Base+.
  #
  # In order to achieve acceptable performance you should implement
  # your own session class, similar to the one provided for Myqsl.
  #
  # Only functions +find_session+, +create_session+,
  # +update_session+ and +destroy+ are required. See file +mysql_session.rb+.

  cattr_accessor :session_class
  @@session_class = SqlSession

  # Create a new SqlSessionStore instance.
  #
  # +session+ is the session for which this instance is being created.
  #
  # +option+ is currently ignored as no options are recognized.

  def initialize(session, option=nil)
    if @session = @@session_class.find_session(session.session_id)
      @data = unmarshalize(@session.data)
    else
      @session = @@session_class.create_session(session.session_id, marshalize({}))
      @data = {}
    end
  end

  # Update the database and disassociate the session object
  def close
    if @session
      @session.update_session(marshalize(@data))
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
      @data = unmarshalize(@session.data)
    end
  end

  # Save session data in the session object
  def update
    if @session
      @session.update_session(marshalize(@data))
    end
  end

  private
  if defined?(Base64)
    def unmarshalize(data)
      Marshal.load(Base64.decode64(data))
    end

    def marshalize(data)
      Base64.encode64(Marshal.dump(data))
    end
  else
    def unmarshalize(data)
      Marshal.load(data.unpack("m").first)
    end

    def marshalize(data)
      [Marshal.dump(data)].pack("m")
    end
  end

end

__END__

# This software is released under the MIT license
#
# Copyright (c) 2005-2008 Stefan Kaes

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

