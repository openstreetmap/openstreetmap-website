require "test_helper"

class MessageControllerTest < ActionController::TestCase
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/user/username/inbox", :method => :get },
      { :controller => "message", :action => "inbox", :display_name => "username" }
    )
    assert_routing(
      { :path => "/user/username/outbox", :method => :get },
      { :controller => "message", :action => "outbox", :display_name => "username" }
    )
    assert_routing(
      { :path => "/message/new/username", :method => :get },
      { :controller => "message", :action => "new", :display_name => "username" }
    )
    assert_routing(
      { :path => "/message/new/username", :method => :post },
      { :controller => "message", :action => "new", :display_name => "username" }
    )
    assert_routing(
      { :path => "/message/read/1", :method => :get },
      { :controller => "message", :action => "read", :message_id => "1" }
    )
    assert_routing(
      { :path => "/message/mark/1", :method => :post },
      { :controller => "message", :action => "mark", :message_id => "1" }
    )
    assert_routing(
      { :path => "/message/reply/1", :method => :get },
      { :controller => "message", :action => "reply", :message_id => "1" }
    )
    assert_routing(
      { :path => "/message/reply/1", :method => :post },
      { :controller => "message", :action => "reply", :message_id => "1" }
    )
    assert_routing(
      { :path => "/message/delete/1", :method => :post },
      { :controller => "message", :action => "delete", :message_id => "1" }
    )
  end

  ##
  # test fetching new message page when not logged in
  def test_new_no_login
    # Check that the new message page requires us to login
    user = create(:user)
    get :new, :params => { :display_name => user.display_name }
    assert_redirected_to login_path(:referer => new_message_path(:display_name => user.display_name))
  end

  ##
  # test fetching new message page when logged in
  def test_new_form
    # Login as a normal user
    user = create(:user)
    recipient_user = create(:user)
    session[:user] = user.id

    # Check that the new message page loads
    get :new, :params => { :display_name => recipient_user.display_name }
    assert_response :success
    assert_template "new"
    assert_select "title", "Send message | OpenStreetMap"
    assert_select "form[action='#{new_message_path(:display_name => recipient_user.display_name)}']", :count => 1 do
      assert_select "input#message_title", :count => 1
      assert_select "textarea#message_body", :count => 1
      assert_select "input[type='submit'][value='Send']", :count => 1
    end
  end

  ##
  # test fetching new message page with body and title
  def test_new_get_with_params
    # Login as a normal user
    user = create(:user)
    recipient_user = create(:user)
    session[:user] = user.id

    # Check that we can't send a message from a GET request
    assert_difference "ActionMailer::Base.deliveries.size", 0 do
      assert_difference "Message.count", 0 do
        get :new,
            :params => { :display_name => recipient_user.display_name,
                         :message => { :title => "Test Message", :body => "Test message body" } }
      end
    end
    assert_response :success
    assert_template "new"
    assert_select "title", "Send message | OpenStreetMap"
    assert_select "form[action='#{new_message_path(:display_name => recipient_user.display_name)}']", :count => 1 do
      assert_select "input#message_title", :count => 1 do
        assert_select "[value='Test Message']"
      end
      assert_select "textarea#message_body", :text => "Test message body", :count => 1
      assert_select "input[type='submit'][value='Send']", :count => 1
    end
  end

  ##
  # test posting new message page with no body
  def test_new_post_no_body
    # Login as a normal user
    user = create(:user)
    recipient_user = create(:user)
    session[:user] = user.id

    # Check that the subject is preserved over errors
    assert_difference "ActionMailer::Base.deliveries.size", 0 do
      assert_difference "Message.count", 0 do
        post :new,
             :params => { :display_name => recipient_user.display_name,
                          :message => { :title => "Test Message", :body => "" } }
      end
    end
    assert_response :success
    assert_template "new"
    assert_select "title", "Send message | OpenStreetMap"
    assert_select "form[action='#{new_message_path(:display_name => recipient_user.display_name)}']", :count => 1 do
      assert_select "input#message_title", :count => 1 do
        assert_select "[value='Test Message']"
      end
      assert_select "textarea#message_body", :text => "", :count => 1
      assert_select "input[type='submit'][value='Send']", :count => 1
    end
  end

  ##
  # test posting new message page with no title
  def test_new_post_no_title
    # Login as a normal user
    user = create(:user)
    recipient_user = create(:user)
    session[:user] = user.id

    # Check that the body text is preserved over errors
    assert_difference "ActionMailer::Base.deliveries.size", 0 do
      assert_difference "Message.count", 0 do
        post :new,
             :params => { :display_name => recipient_user.display_name,
                          :message => { :title => "", :body => "Test message body" } }
      end
    end
    assert_response :success
    assert_template "new"
    assert_select "title", "Send message | OpenStreetMap"
    assert_select "form[action='#{new_message_path(:display_name => recipient_user.display_name)}']", :count => 1 do
      assert_select "input#message_title", :count => 1 do
        assert_select "[value='']"
      end
      assert_select "textarea#message_body", :text => "Test message body", :count => 1
      assert_select "input[type='submit'][value='Send']", :count => 1
    end
  end

  ##
  # test posting new message page sends message
  def test_new_post_send
    # Login as a normal user
    user = create(:user)
    recipient_user = create(:user)
    session[:user] = user.id

    # Check that sending a message works
    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      assert_difference "Message.count", 1 do
        post :new,
             :params => { :display_name => recipient_user.display_name,
                          :message => { :title => "Test Message", :body => "Test message body" } }
      end
    end
    assert_redirected_to inbox_path(:display_name => user.display_name)
    assert_equal "Message sent", flash[:notice]
    e = ActionMailer::Base.deliveries.first
    assert_equal [recipient_user.email], e.to
    assert_equal "[OpenStreetMap] Test Message", e.subject
    assert_match /Test message body/, e.text_part.decoded
    assert_match /Test message body/, e.html_part.decoded
    ActionMailer::Base.deliveries.clear
    m = Message.last
    assert_equal user.id, m.from_user_id
    assert_equal recipient_user.id, m.to_user_id
    assert_in_delta Time.now, m.sent_on, 2
    assert_equal "Test Message", m.title
    assert_equal "Test message body", m.body
    assert_equal "markdown", m.body_format

    # Asking to send a message with a bogus user name should fail
    get :new, :params => { :display_name => "non_existent_user" }
    assert_response :not_found
    assert_template "user/no_such_user"
    assert_select "h1", "The user non_existent_user does not exist"
  end

  ##
  # test the new action message limit
  def test_new_limit
    # Login as a normal user
    user = create(:user)
    recipient_user = create(:user)
    session[:user] = user.id

    # Check that sending a message fails when the message limit is hit
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      assert_no_difference "Message.count" do
        with_message_limit(0) do
          post :new,
               :params => { :display_name => recipient_user.display_name,
                            :message => { :title => "Test Message", :body => "Test message body" } }
          assert_response :success
          assert_template "new"
          assert_select ".error", /wait a while/
        end
      end
    end
  end

  ##
  # test the reply action
  def test_reply
    user = create(:user)
    recipient_user = create(:user)
    other_user = create(:user)
    unread_message = create(:message, :unread, :sender => user, :recipient => recipient_user)

    # Check that the message reply page requires us to login
    get :reply, :params => { :message_id => unread_message.id }
    assert_redirected_to login_path(:referer => reply_message_path(:message_id => unread_message.id))

    # Login as the wrong user
    session[:user] = other_user.id

    # Check that we can't reply to somebody else's message
    get :reply, :params => { :message_id => unread_message.id }
    assert_redirected_to login_path(:referer => reply_message_path(:message_id => unread_message.id))
    assert_equal "You are logged in as `#{other_user.display_name}' but the message you have asked to reply to was not sent to that user. Please login as the correct user in order to reply.", flash[:notice]

    # Login as the right user
    session[:user] = recipient_user.id

    # Check that the message reply page loads
    get :reply, :params => { :message_id => unread_message.id }
    assert_response :success
    assert_template "new"
    assert_select "title", "Re: #{unread_message.title} | OpenStreetMap"
    assert_select "form[action='#{new_message_path(:display_name => user.display_name)}']", :count => 1 do
      assert_select "input#message_title[value='Re: #{unread_message.title}']", :count => 1
      assert_select "textarea#message_body", :count => 1
      assert_select "input[type='submit'][value='Send']", :count => 1
    end
    assert_equal true, Message.find(unread_message.id).message_read

    # Asking to reply to a message with no ID should fail
    assert_raise ActionController::UrlGenerationError do
      get :reply
    end

    # Asking to reply to a message with a bogus ID should fail
    get :reply, :params => { :message_id => 99999 }
    assert_response :not_found
    assert_template "no_such_message"
  end

  ##
  # test the read action
  def test_read
    user = create(:user)
    recipient_user = create(:user)
    other_user = create(:user)
    unread_message = create(:message, :unread, :sender => user, :recipient => recipient_user)

    # Check that the read message page requires us to login
    get :read, :params => { :message_id => unread_message.id }
    assert_redirected_to login_path(:referer => read_message_path(:message_id => unread_message.id))

    # Login as the wrong user
    session[:user] = other_user.id

    # Check that we can't read the message
    get :read, :params => { :message_id => unread_message.id }
    assert_redirected_to login_path(:referer => read_message_path(:message_id => unread_message.id))
    assert_equal "You are logged in as `#{other_user.display_name}' but the message you have asked to read was not sent by or to that user. Please login as the correct user in order to read it.", flash[:notice]

    # Login as the message sender
    session[:user] = user.id

    # Check that the message sender can read the message
    get :read, :params => { :message_id => unread_message.id }
    assert_response :success
    assert_template "read"
    assert_equal false, Message.find(unread_message.id).message_read

    # Login as the message recipient
    session[:user] = recipient_user.id

    # Check that the message recipient can read the message
    get :read, :params => { :message_id => unread_message.id }
    assert_response :success
    assert_template "read"
    assert_equal true, Message.find(unread_message.id).message_read

    # Asking to read a message with no ID should fail
    assert_raise ActionController::UrlGenerationError do
      get :read
    end

    # Asking to read a message with a bogus ID should fail
    get :read, :params => { :message_id => 99999 }
    assert_response :not_found
    assert_template "no_such_message"
  end

  ##
  # test the inbox action
  def test_inbox
    user = create(:user)
    other_user = create(:user)
    read_message = create(:message, :read, :recipient => user)
    # Check that the inbox page requires us to login
    get :inbox, :params => { :display_name => user.display_name }
    assert_redirected_to login_path(:referer => inbox_path(:display_name => user.display_name))

    # Login
    session[:user] = user.id

    # Check that we can view our inbox when logged in
    get :inbox, :params => { :display_name => user.display_name }
    assert_response :success
    assert_template "inbox"
    assert_select "table.messages", :count => 1 do
      assert_select "tr", :count => 2
      assert_select "tr#inbox-#{read_message.id}.inbox-row", :count => 1
    end

    # Check that we can't view somebody else's inbox when logged in
    get :inbox, :params => { :display_name => other_user.display_name }
    assert_redirected_to inbox_path(:display_name => user.display_name)
  end

  ##
  # test the outbox action
  def test_outbox
    user = create(:user)
    other_user = create(:user)
    create(:message, :sender => user)

    # Check that the outbox page requires us to login
    get :outbox, :params => { :display_name => user.display_name }
    assert_redirected_to login_path(:referer => outbox_path(:display_name => user.display_name))

    # Login
    session[:user] = user.id

    # Check that we can view our outbox when logged in
    get :outbox, :params => { :display_name => user.display_name }
    assert_response :success
    assert_template "outbox"
    assert_select "table.messages", :count => 1 do
      assert_select "tr", :count => 2
      assert_select "tr.inbox-row", :count => 1
    end

    # Check that we can't view somebody else's outbox when logged in
    get :outbox, :params => { :display_name => other_user.display_name }
    assert_redirected_to outbox_path(:display_name => user.display_name)
  end

  ##
  # test the mark action
  def test_mark
    user = create(:user)
    recipient_user = create(:user)
    other_user = create(:user)
    unread_message = create(:message, :unread, :sender => user, :recipient => recipient_user)

    # Check that the marking a message requires us to login
    post :mark, :params => { :message_id => unread_message.id }
    assert_response :forbidden

    # Login as a user with no messages
    session[:user] = other_user.id

    # Check that marking a message we didn't send or receive fails
    post :mark, :params => { :message_id => unread_message.id }
    assert_response :not_found
    assert_template "no_such_message"

    # Login as the message recipient_user
    session[:user] = recipient_user.id

    # Check that the marking a message read works
    post :mark, :params => { :message_id => unread_message.id, :mark => "read" }
    assert_redirected_to inbox_path(:display_name => recipient_user.display_name)
    assert_equal true, Message.find(unread_message.id).message_read

    # Check that the marking a message unread works
    post :mark, :params => { :message_id => unread_message.id, :mark => "unread" }
    assert_redirected_to inbox_path(:display_name => recipient_user.display_name)
    assert_equal false, Message.find(unread_message.id).message_read

    # Check that the marking a message read via XHR works
    post :mark, :xhr => true, :params => { :message_id => unread_message.id, :mark => "read" }
    assert_response :success
    assert_template "mark"
    assert_equal true, Message.find(unread_message.id).message_read

    # Check that the marking a message unread via XHR works
    post :mark, :xhr => true, :params => { :message_id => unread_message.id, :mark => "unread" }
    assert_response :success
    assert_template "mark"
    assert_equal false, Message.find(unread_message.id).message_read

    # Asking to mark a message with no ID should fail
    assert_raise ActionController::UrlGenerationError do
      post :mark
    end

    # Asking to mark a message with a bogus ID should fail
    post :mark, :params => { :message_id => 99999 }
    assert_response :not_found
    assert_template "no_such_message"
  end

  ##
  # test the delete action
  def test_delete
    user = create(:user)
    second_user = create(:user)
    other_user = create(:user)
    read_message = create(:message, :read, :recipient => user, :sender => second_user)
    sent_message = create(:message, :unread, :recipient => second_user, :sender => user)

    # Check that the deleting a message requires us to login
    post :delete, :params => { :message_id => read_message.id }
    assert_response :forbidden

    # Login as a user with no messages
    session[:user] = other_user.id

    # Check that deleting a message we didn't send or receive fails
    post :delete, :params => { :message_id => read_message.id }
    assert_response :not_found
    assert_template "no_such_message"

    # Login as the message recipient_user
    session[:user] = user.id

    # Check that the deleting a received message works
    post :delete, :params => { :message_id => read_message.id }
    assert_redirected_to inbox_path(:display_name => user.display_name)
    assert_equal "Message deleted", flash[:notice]
    m = Message.find(read_message.id)
    assert_equal true, m.from_user_visible
    assert_equal false, m.to_user_visible

    # Check that the deleting a sent message works
    post :delete, :params => { :message_id => sent_message.id, :referer => outbox_path(:display_name => user.display_name) }
    assert_redirected_to outbox_path(:display_name => user.display_name)
    assert_equal "Message deleted", flash[:notice]
    m = Message.find(sent_message.id)
    assert_equal false, m.from_user_visible
    assert_equal true, m.to_user_visible

    # Asking to delete a message with no ID should fail
    assert_raise ActionController::UrlGenerationError do
      post :delete
    end

    # Asking to delete a message with a bogus ID should fail
    post :delete, :params => { :message_id => 99999 }
    assert_response :not_found
    assert_template "no_such_message"
  end

  private

  def with_message_limit(value)
    max_messages_per_hour = Object.send("remove_const", "MAX_MESSAGES_PER_HOUR")
    Object.const_set("MAX_MESSAGES_PER_HOUR", value)

    yield

    Object.send("remove_const", "MAX_MESSAGES_PER_HOUR")
    Object.const_set("MAX_MESSAGES_PER_HOUR", max_messages_per_hour)
  end
end
