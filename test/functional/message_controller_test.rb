require File.dirname(__FILE__) + '/../test_helper'

class MessageControllerTest < ActionController::TestCase
  fixtures :users, :messages

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
  # test the new action
  def test_new
    # Check that the new message page requires us to login
    get :new, :display_name => users(:public_user).display_name
    assert_redirected_to login_path(:referer => new_message_path(:display_name => users(:public_user).display_name))

    # Login as a normal user
    session[:user] = users(:normal_user).id

    # Check that the new message page loads
    get :new, :display_name => users(:public_user).display_name
    assert_response :success
    assert_template "new"
    assert_select "title", "OpenStreetMap | Send message"
    assert_select "form[action='#{new_message_path(:display_name => users(:public_user).display_name)}']", :count => 1 do
      assert_select "input#message_title", :count => 1
      assert_select "textarea#message_body", :count => 1
      assert_select "input[type='submit'][value='Send']", :count => 1
    end

    # Check that sending a message works
    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      assert_difference "Message.count", 1 do
        post :new,
          :display_name => users(:public_user).display_name,
          :message => { :title => "Test Message", :body => "Test message body" }
      end
    end
    assert_redirected_to inbox_path(:display_name => users(:normal_user).display_name)
    assert_equal "Message sent", flash[:notice]
    e = ActionMailer::Base.deliveries.first
    assert_equal [ users(:public_user).email ], e.to
    assert_equal "[OpenStreetMap] Test Message", e.subject
    assert_match /Test message body/, e.text_part.decoded
    assert_match /Test message body/, e.html_part.decoded
    ActionMailer::Base.deliveries.clear
    m = Message.find(3)
    assert_equal users(:normal_user).id, m.from_user_id
    assert_equal users(:public_user).id, m.to_user_id
    assert_in_delta Time.now, m.sent_on, 2
    assert_equal "Test Message", m.title
    assert_equal "Test message body", m.body
    assert_equal "markdown", m.body_format

    # Asking to send a message with a bogus user name should fail
    get :new, :display_name => "non_existent_user"
    assert_response :not_found
    assert_template "user/no_such_user"
    assert_select "h2", "The user non_existent_user does not exist"
  end

  ##
  # test the reply action
  def test_reply
    # Check that the message reply page requires us to login
    get :reply, :message_id => messages(:unread_message).id
    assert_redirected_to login_path(:referer => reply_message_path(:message_id => messages(:unread_message).id))

    # Login as the wrong user
    session[:user] = users(:second_public_user).id

    # Check that we can't reply to somebody else's message
    get :reply, :message_id => messages(:unread_message).id
    assert_redirected_to login_path(:referer => reply_message_path(:message_id => messages(:unread_message).id))
    assert_equal "You are logged in as `pulibc_test2' but the message you have asked to reply to was not sent to that user. Please login as the correct user in order to reply.", flash[:notice]

    # Login as the right user
    session[:user] = users(:public_user).id

    # Check that the message reply page loads
    get :reply, :message_id => messages(:unread_message).id
    assert_response :success
    assert_template "new"
    assert_select "title", "OpenStreetMap | Re: test message 1"
    assert_select "form[action='#{new_message_path(:display_name => users(:normal_user).display_name)}']", :count => 1 do
      assert_select "input#message_title[value='Re: test message 1']", :count => 1
      assert_select "textarea#message_body", :count => 1
      assert_select "input[type='submit'][value='Send']", :count => 1
    end
    assert_equal true, Message.find(messages(:unread_message).id).message_read

    # Asking to reply to a message with no ID should fail
    assert_raise ActionController::UrlGenerationError do
      get :reply
    end

    # Asking to reply to a message with a bogus ID should fail
    get :reply, :message_id => 99999
    assert_response :not_found
    assert_template "no_such_message"
  end

  ##
  # test the read action
  def test_read
    # Check that the read message page requires us to login
    get :read, :message_id => messages(:unread_message).id
    assert_redirected_to login_path(:referer => read_message_path(:message_id => messages(:unread_message).id))

    # Login as the wrong user
    session[:user] = users(:second_public_user).id

    # Check that we can't read the message
    get :read, :message_id => messages(:unread_message).id
    assert_redirected_to login_path(:referer => read_message_path(:message_id => messages(:unread_message).id))
    assert_equal "You are logged in as `pulibc_test2' but the message you have asked to read was not sent by or to that user. Please login as the correct user in order to read it.", flash[:notice]

    # Login as the message sender
    session[:user] = users(:normal_user).id

    # Check that the message sender can read the message
    get :read, :message_id => messages(:unread_message).id
    assert_response :success
    assert_template "read"
    assert_equal false, Message.find(messages(:unread_message).id).message_read

    # Login as the message recipient
    session[:user] = users(:public_user).id

    # Check that the message recipient can read the message
    get :read, :message_id => messages(:unread_message).id
    assert_response :success
    assert_template "read"
    assert_equal true, Message.find(messages(:unread_message).id).message_read

    # Asking to read a message with no ID should fail
    assert_raise ActionController::UrlGenerationError do
      get :read
    end

    # Asking to read a message with a bogus ID should fail
    get :read, :message_id => 99999
    assert_response :not_found
    assert_template "no_such_message"
  end

  ##
  # test the inbox action
  def test_inbox
    # Check that the inbox page requires us to login
    get :inbox, :display_name => users(:normal_user).display_name
    assert_redirected_to login_path(:referer => inbox_path(:display_name => users(:normal_user).display_name))

    # Login
    session[:user] = users(:normal_user).id

    # Check that we can view our inbox when logged in
    get :inbox, :display_name => users(:normal_user).display_name
    assert_response :success
    assert_template "inbox"
    assert_select "table.messages", :count => 1 do
      assert_select "tr", :count => 2
      assert_select "tr#inbox-#{messages(:read_message).id}.inbox-row", :count => 1
    end

    # Check that we can't view somebody else's inbox when logged in
    get :inbox, :display_name => users(:public_user).display_name
    assert_redirected_to inbox_path(:display_name => users(:normal_user).display_name)
  end

  ##
  # test the outbox action
  def test_outbox
    # Check that the outbox page requires us to login
    get :outbox, :display_name => users(:normal_user).display_name
    assert_redirected_to login_path(:referer => outbox_path(:display_name => users(:normal_user).display_name))

    # Login
    session[:user] = users(:normal_user).id

    # Check that we can view our outbox when logged in
    get :outbox, :display_name => users(:normal_user).display_name
    assert_response :success
    assert_template "outbox"
    assert_select "table.messages", :count => 1 do
      assert_select "tr", :count => 2
      assert_select "tr.inbox-row", :count => 1
    end

    # Check that we can't view somebody else's outbox when logged in
    get :outbox, :display_name => users(:public_user).display_name
    assert_redirected_to outbox_path(:display_name => users(:normal_user).display_name)
  end

  ##
  # test the mark action
  def test_mark
    # Check that the marking a message requires us to login
    post :mark, :message_id => messages(:unread_message).id
    assert_response :forbidden

    # Login as a user with no messages
    session[:user] = users(:second_public_user).id

    # Check that marking a message we didn't send or receive fails
    post :mark, :message_id => messages(:read_message).id
    assert_response :not_found
    assert_template "no_such_message"

    # Login as the message recipient
    session[:user] = users(:public_user).id

    # Check that the marking a message read works
    post :mark, :message_id => messages(:unread_message).id, :mark => "read"
    assert_redirected_to inbox_path(:display_name => users(:public_user).display_name)
    assert_equal true, Message.find(messages(:unread_message).id).message_read

    # Check that the marking a message unread works
    post :mark, :message_id => messages(:unread_message).id, :mark => "unread"
    assert_redirected_to inbox_path(:display_name => users(:public_user).display_name)
    assert_equal false, Message.find(messages(:unread_message).id).message_read

    # Check that the marking a message read via XHR works
    xhr :post, :mark, :message_id => messages(:unread_message).id, :mark => "read"
    assert_response :success
    assert_template "mark"
    assert_equal true, Message.find(messages(:unread_message).id).message_read

    # Check that the marking a message unread via XHR works
    xhr :post, :mark, :message_id => messages(:unread_message).id, :mark => "unread"
    assert_response :success
    assert_template "mark"
    assert_equal false, Message.find(messages(:unread_message).id).message_read

    # Asking to mark a message with no ID should fail
    assert_raise ActionController::UrlGenerationError do
      post :mark
    end

    # Asking to mark a message with a bogus ID should fail
    post :mark, :message_id => 99999
    assert_response :not_found
    assert_template "no_such_message"
  end

  ##
  # test the delete action
  def test_delete
    # Check that the deleting a message requires us to login
    post :delete, :message_id => messages(:read_message).id
    assert_response :forbidden

    # Login as a user with no messages
    session[:user] = users(:second_public_user).id

    # Check that deleting a message we didn't send or receive fails
    post :delete, :message_id => messages(:read_message).id
    assert_response :not_found
    assert_template "no_such_message"

    # Login as the message recipient
    session[:user] = users(:normal_user).id

    # Check that the deleting a received message works
    post :delete, :message_id => messages(:read_message).id
    assert_redirected_to inbox_path(:display_name => users(:normal_user).display_name)
    assert_equal "Message deleted", flash[:notice]
    m = Message.find(messages(:read_message).id)
    assert_equal true, m.from_user_visible
    assert_equal false, m.to_user_visible

    # Check that the deleting a sent message works
    post :delete, :message_id => messages(:unread_message).id
    assert_redirected_to inbox_path(:display_name => users(:normal_user).display_name)
    assert_equal "Message deleted", flash[:notice]
    m = Message.find(messages(:unread_message).id)
    assert_equal false, m.from_user_visible
    assert_equal true, m.to_user_visible

    # Asking to delete a message with no ID should fail
    assert_raise ActionController::UrlGenerationError do
      post :delete
    end

    # Asking to delete a message with a bogus ID should fail
    post :delete, :message_id => 99999
    assert_response :not_found
    assert_template "no_such_message"
  end
end
