require 'mysql'

# allow access to the real Mysql connection
class ActiveRecord::ConnectionAdapters::MysqlAdapter
  attr_reader :connection
end

# MysqlSession is a down to the bare metal session store
# implementation to be used with +SQLSessionStore+. It is much faster
# than the default ActiveRecord implementation.
#
# The implementation assumes that the table column names are 'id',
# 'data', 'created_at' and 'updated_at'. If you want use other names,
# you will need to change the SQL statments in the code.

class MysqlSession

  # if you need Rails components, and you have a pages which create
  # new sessions, and embed components insides this pages that need
  # session access, then you *must* set +eager_session_creation+ to
  # true (as of Rails 1.0).
  cattr_accessor :eager_session_creation
  @@eager_session_creation = false

  attr_accessor :id, :session_id, :data

  def initialize(session_id, data)
    @session_id = session_id
    @data = data
    @id = nil
  end

  class << self

    # retrieve the session table connection and get the 'raw' Mysql connection from it
    def session_connection
      SqlSession.connection.connection
    end

    # try to find a session with a given +session_id+. returns nil if
    # no such session exists. note that we don't retrieve
    # +created_at+ and +updated_at+ as they are not accessed anywhyere
    # outside this class
    def find_session(session_id)
      connection = session_connection
      connection.query_with_result = true
      session_id = Mysql::quote(session_id)
      result = connection.query("SELECT id, data FROM sessions WHERE `session_id`='#{session_id}' LIMIT 1")
      my_session = nil
      # each is used below, as other methods barf on my 64bit linux machine
      # I suspect this to be a bug in mysql-ruby
      result.each do |row|
        my_session = new(session_id, row[1])
        my_session.id = row[0]
      end
      result.free
      my_session
    end

    # create a new session with given +session_id+ and +data+
    # and save it immediately to the database
    def create_session(session_id, data)
      session_id = Mysql::quote(session_id)
      new_session = new(session_id, data)
      if @@eager_session_creation
        connection = session_connection
        connection.query("INSERT INTO sessions (`created_at`, `updated_at`, `session_id`, `data`) VALUES (NOW(), NOW(), '#{session_id}', '#{Mysql::quote(data)}')")
        new_session.id = connection.insert_id
      end
      new_session
    end

    # delete all sessions meeting a given +condition+. it is the
    # caller's responsibility to pass a valid sql condition
    def delete_all(condition=nil)
      if condition
        session_connection.query("DELETE FROM sessions WHERE #{condition}")
      else
        session_connection.query("DELETE FROM sessions")
      end
    end

  end # class methods

  # update session with given +data+.
  # unlike the default implementation using ActiveRecord, updating of
  # column `updated_at` will be done by the datbase itself
  def update_session(data)
    connection = self.class.session_connection
    if @id
      # if @id is not nil, this is a session already stored in the database
      # update the relevant field using @id as key
      connection.query("UPDATE sessions SET `updated_at`=NOW(), `data`='#{Mysql::quote(data)}' WHERE id=#{@id}")
    else
      # if @id is nil, we need to create a new session in the database
      # and set @id to the primary key of the inserted record
      connection.query("INSERT INTO sessions (`created_at`, `updated_at`, `session_id`, `data`) VALUES (NOW(), NOW(), '#{@session_id}', '#{Mysql::quote(data)}')")
      @id = connection.insert_id
    end
  end

  # destroy the current session
  def destroy
    self.class.delete_all("session_id='#{session_id}'")
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
