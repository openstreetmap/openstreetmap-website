# Copyright (c) 2010 August Lilleaas
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

module SessionPersistence
  class << self
    private

    # Install filter when we are included
    def included(controller)
      controller.after_action :persist_session
    end
  end

  private

  # Override this method if you don't want to use session[:_remember_for].
  def session_persistence_key
    :_remember_for
  end

  # Persist the session.
  #
  #   session_expires_after 1.hour
  #   session_expires_after 2.weeks
  def session_expires_after(seconds)
    session[session_persistence_key] = seconds
  end

  # Expire the session.
  def session_expires_automatically
    session.delete(session_persistence_key)
    request.session_options[:renew] = true
  end

  # Filter callback
  def persist_session
    if session[session_persistence_key]
      request.session_options[:expire_after] = session[session_persistence_key]
    end
  rescue
    reset_session
  end
end
