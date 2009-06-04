require 'oci8'

# OracleSession is a down to the bare metal session store
# implementation to be used with +SQLSessionStore+. It is much faster
# than the default ActiveRecord implementation.
#
# The implementation assumes that the table column names are 'id',
# 'session_id', 'data', 'created_at' and 'updated_at'. If you want use
# other names, you will need to change the SQL statments in the code.
#
# This table layout is compatible with ActiveRecordStore.

class OracleSession < AbstractSession
  class << self
    # try to find a session with a given +session_id+. returns nil if
    # no such session exists. note that we don't retrieve
    # +created_at+ and +updated_at+ as they are not accessed anywhyere
    # outside this class.
    def find_session(session_id)
      new_session = nil

      # Make sure to save the @id if we find an existing session
      cursor = session_connection.exec(find_session_sql, session_id)
      if row = cursor.fetch_hash
        new_session = new(session_id, unmarshalize(row['DATA'].read), row['ID'])

        # Pull out native columns
        native_columns.each do |col|
          new_session.data[col] = row[col.to_s.upcase]
          new_session.data[col] = row[col.to_s.upcase]
        end
      end

      cursor.close
      new_session
    end

    # create a new session with given +session_id+ and +data+
    # and save it immediately to the database
    def create_session(session_id, data={})
      new_session = new(session_id, data)
      if eager_session_creation
        new_session.id = next_id
        cursor = session_connection.parse(insert_session_sql)

        # Now bind all variables
        cursor.bind_param(':id', new_session.id)
        cursor.bind_param(':session_id', session_id)
        native_columns.each do |col|
          cursor.bind_param(":#{col}", data.delete(col) || '')
        end
        cursor.bind_param(':data', marshalize(data))
        cursor.exec
        cursor.close
      end
      new_session
    end

    # Internal methods for generating SQL
    # Get the next ID from the sequence
    def next_id
      cursor = session_connection.exec("SELECT #{table_name}_seq.nextval FROM dual")
      id = cursor.fetch.first.to_i
      cursor.close
      id
    end

    # Dynamically generate finder SQL so we can include our special columns
    def find_session_sql
      @find_session_sql ||=
        "SELECT " + ([:id, :data] + native_columns).join(', ') +
        " FROM #{table_name} WHERE session_id = :session_id AND rownum = 1"
    end

    def insert_session_sql
      @insert_session_sql ||=
        "INSERT INTO #{table_name} (" + ([:id, :data, :session_id] + native_columns + [:created_at, :updated_at]).join(', ') + ")" + 
        " VALUES (" + ([:id, :data, :session_id] + native_columns).collect{|col| ":#{col}" }.join(', ') + 
        " , SYSDATE, SYSDATE)"
    end

    def update_session_sql
      @update_session_sql ||=
        "UPDATE #{table_name} SET "+
        ([:data] + native_columns).collect{|col| "#{col} = :#{col}"}.join(', ') +
        " , updated_at = SYSDATE WHERE ID = :id"
    end
  end # class methods

  # update session with given +data+.
  # unlike the default implementation using ActiveRecord, updating of
  # column `updated_at` will be done by the database itself
  def update_session(data)
    connection = self.class.session_connection
    cursor = nil
    if @id
      # if @id is not nil, this is a session already stored in the database
      # update the relevant field using @id as key
      cursor = connection.parse(self.class.update_session_sql)
    else
      # if @id is nil, we need to create a new session in the database
      # and set @id to the primary key of the inserted record
      @id = self.class.next_id

      cursor = connection.parse(self.class.insert_session_sql)
      cursor.bind_param(':session_id', @session_id)
    end

    # These are always the same, as @id is set above!
    cursor.bind_param(':id', @id, Fixnum) 
    native_columns.each do |col|
      cursor.bind_param(":#{col}", data.delete(col) || '')
    end
    cursor.bind_param(':data', self.class.marshalize(data))
    cursor.exec
    cursor.close
  end

  # destroy the current session
  def destroy
    self.class.delete_all(["session_id = ?", session_id])
  end

end

__END__

# This software is released under the MIT license
#
# Copyright (c) 2006 Stefan Kaes
# Copyright (c) 2006 Tiago Macedo
# Copyright (c) 2007 Nate Wiger
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

