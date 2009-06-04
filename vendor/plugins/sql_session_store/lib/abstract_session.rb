#
# This is a common base class for database-specific session store implementations
#
require 'cgi/session'
require 'base64'

class AbstractSession
  # if you need Rails components, and you have a pages which create
  # new sessions, and embed components insides this pages that need
  # session access, then you *must* set +eager_session_creation+ to
  # true (as of Rails 1.0).
  cattr_accessor :eager_session_creation
  @@eager_session_creation = false

  # Some attributes you may want to store natively in the database
  # in actual columns. This allows other models and database queries
  # to get to the data without having to unmarshal the data blob.
  # One common example is the user_id of the session, so it can be
  # related to the users table
  cattr_accessor :native_columns
  @@native_columns = []

  # Allow the user to change the table name
  cattr_accessor :table_name
  @@table_name = 'sessions'

  cattr_reader :timestamp_columns
  @@timestamp_columns = [:created_at, :updated_at]

  attr_accessor :id, :session_id, :data

  def initialize(session_id, data, id=nil)
    @session_id = session_id
    @data = data
    @id = id
  end

  class << self
    # delete all sessions meeting a given +condition+. it is the
    # caller's responsibility to pass a valid sql condition
    def delete_all(condition=nil)
      if condition
        session_connection.exec("DELETE FROM sessions WHERE #{condition}")
      else
        session_connection.exec("DELETE FROM sessions")
      end
    end

    # retrieve the session table connection and get the 'raw' driver connection from it
    def session_connection
      SqlSession.connection.raw_connection
    end

    def unmarshalize(data)
      Marshal.load(Base64.decode64(data))
    end

    def marshalize(data)
      Base64.encode64(Marshal.dump(data))
    end
  end
end

__END__

# This software is released under the MIT license
#
# Copyright (c) 2005, 2006, 2008 Stefan Kaes
# Copyright (c) 2008, 2009 Nate Wiger
#
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
