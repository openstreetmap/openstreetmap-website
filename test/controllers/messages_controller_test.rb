require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/messages/new/username", :method => :get },
      { :controller => "messages", :action => "new", :display_name => "username" }
    )
    assert_routing(
      { :path => "/messages", :method => :post },
      { :controller => "messages", :action => "create" }
    )
    assert_routing(
      { :path => "/messages/1", :method => :get },
      { :controller => "messages", :action => "show", :id => "1" }
    )
    assert_routing(
      { :path => "/messages/1", :method => :delete },
      { :controller => "messages", :action => "destroy", :id => "1" }
    )
  end

  ##
  # test fetching new message page when not logged in
  def test_new_no_login
    # Check that the new message page requires us to login
    user = create(:user)
    get new_message_path(user)
    assert_redirected_to login_path(:referer => new_message_path(user))
  end

  ##
  # test fetching new message page when logged in
  def test_new_form
    # Login as a normal user
    user = create(:user)
    recipient_user = create(:user)
    session_for(user)

    # Check that the new message page loads
    get new_message_path(recipient_user)
    assert_response :success
    assert_template "new"
    assert_select "title", "Send message | OpenStreetMap"
    assert_select "a[href='#{user_path recipient_user}']", :text => recipient_user.display_name
    assert_select "form[action='/messages']", :count => 1 do
      assert_select "input[type='hidden'][name='display_name'][value='#{recipient_user.display_name}']"
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
    session_for(user)

    # Check that we can't send a message from a GET request
    assert_difference "ActionMailer::Base.deliveries.size", 0 do
      assert_difference "Message.count", 0 do
        perform_enqueued_jobs do
          get new_message_path(recipient_user, :message => { :title => "Test Message", :body => "Test message body" })
        end
      end
    end
    assert_response :success
    assert_template "new"
    assert_select "title", "Send message | OpenStreetMap"
    assert_select "form[action='/messages']", :count => 1 do
      assert_select "input[type='hidden'][name='display_name'][value='#{recipient_user.display_name}']"
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
    session_for(user)

    # Check that the subject is preserved over errors
    assert_difference "ActionMailer::Base.deliveries.size", 0 do
      assert_difference "Message.count", 0 do
        perform_enqueued_jobs do
          post messages_path(:display_name => recipient_user.display_name,
                             :message => { :title => "Test Message", :body => "" })
        end
      end
    end
    assert_response :success
    assert_template "new"
    assert_select "title", "Send message | OpenStreetMap"
    assert_select "form[action='/messages']", :count => 1 do
      assert_select "input[type='hidden'][name='display_name'][value='#{recipient_user.display_name}']"
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
    session_for(user)

    # Check that the body text is preserved over errors
    assert_difference "ActionMailer::Base.deliveries.size", 0 do
      assert_difference "Message.count", 0 do
        perform_enqueued_jobs do
          post messages_path(:display_name => recipient_user.display_name,
                             :message => { :title => "", :body => "Test message body" })
        end
      end
    end
    assert_response :success
    assert_template "new"
    assert_select "title", "Send message | OpenStreetMap"
    assert_select "form[action='/messages']", :count => 1 do
      assert_select "input[type='hidden'][name='display_name'][value='#{recipient_user.display_name}']"
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
    session_for(user)

    # Check that sending a message works
    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      assert_difference "Message.count", 1 do
        perform_enqueued_jobs do
          post messages_path(:display_name => recipient_user.display_name,
                             :message => { :title => "Test Message", :body => "Test message body" })
        end
      end
    end
    assert_redirected_to messages_outbox_path
    assert_equal "Message sent", flash[:notice]
    e = ActionMailer::Base.deliveries.first
    assert_equal [recipient_user.email], e.to
    assert_equal "[OpenStreetMap] Test Message", e.subject
    assert_match(/Test message body/, e.text_part.decoded)
    assert_match(/Test message body/, e.html_part.decoded)
    assert_match %r{#{Settings.server_url}/messages/[0-9]+}, e.text_part.decoded

    m = Message.last
    assert_equal user.id, m.from_user_id
    assert_equal recipient_user.id, m.to_user_id
    assert_in_delta Time.now.utc, m.sent_on, 2
    assert_equal "Test Message", m.title
    assert_equal "Test message body", m.body
    assert_equal "markdown", m.body_format

    # Asking to send a message with a bogus user name should fail
    get new_message_path("non_existent_user")
    assert_response :not_found
    assert_template "users/no_such_user"
    assert_select "h1", "The user non_existent_user does not exist"
  end

  ##
  # test the new action message limit
  def test_new_limit
    # Login as a normal user
    user = create(:user)
    recipient_user = create(:user)
    session_for(user)

    # Check that sending a message fails when the message limit is hit
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      assert_no_difference "Message.count" do
        with_settings(:max_messages_per_hour => 0) do
          perform_enqueued_jobs do
            post messages_path(:display_name => recipient_user.display_name,
                               :message => { :title => "Test Message", :body => "Test message body" })
            assert_response :success
            assert_template "new"
            assert_select ".alert.alert-danger", /wait a while/
          end
        end
      end
    end
  end

  ##
  # test the show action
  def test_show
    user = create(:user)
    recipient_user = create(:user)
    other_user = create(:user)
    message = create(:message, :unread, :sender => user, :recipient => recipient_user)

    # Check that the show message page requires us to login
    get message_path(message)
    assert_redirected_to login_path(:referer => message_path(message))

    # Login as the wrong user
    session_for(other_user)

    # Check that we can't read the message
    get message_path(message)
    assert_redirected_to login_path(:referer => message_path(message))
    assert_equal "You are logged in as '#{other_user.display_name}' but the message you have asked to read was not sent by or to that user. Please log in as the correct user in order to read it.", flash[:notice]

    # Login as the message sender
    session_for(user)

    # Check that the message sender can read the message and that Reply button is available
    get message_path(message)
    assert_response :success
    assert_template "show"
    assert_select "a[href='#{user_path recipient_user}']", :text => recipient_user.display_name
    assert_select "a.btn.btn-primary", :text => "Reply"
    assert_not Message.find(message.id).message_read

    # Login as the message recipient
    session_for(recipient_user)

    # Check that the message recipient can read the message and that Reply button is available
    get message_path(message)
    assert_response :success
    assert_template "show"
    assert_select "a[href='#{user_path user}']", :text => user.display_name
    assert_select "a.btn.btn-primary", :text => "Reply"
    assert Message.find(message.id).message_read

    # Asking to read a message with a bogus ID should fail
    get message_path(99999)
    assert_response :not_found
    assert_template "no_such_message"
  end

  ##
  # test the destroy action
  def test_destroy
    user = create(:user)
    second_user = create(:user)
    other_user = create(:user)
    read_message = create(:message, :read, :recipient => user, :sender => second_user)
    sent_message = create(:message, :unread, :recipient => second_user, :sender => user)

    # Check that destroying a message requires us to login
    delete message_path(read_message)
    assert_response :forbidden

    # Login as a user with no messages
    session_for(other_user)

    # Check that destroying a message we didn't send or receive fails
    delete message_path(read_message)
    assert_response :not_found
    assert_template "no_such_message"

    # Login as the message recipient_user
    session_for(user)

    # Check that the destroy a received message works
    delete message_path(read_message)
    assert_redirected_to messages_inbox_path
    assert_equal "Message deleted", flash[:notice]
    m = Message.find(read_message.id)
    assert m.from_user_visible
    assert_not m.to_user_visible

    # Check that the destroying a sent message works
    delete message_path(sent_message, :referer => messages_outbox_path)
    assert_redirected_to messages_outbox_path
    assert_equal "Message deleted", flash[:notice]
    m = Message.find(sent_message.id)
    assert_not m.from_user_visible
    assert m.to_user_visible

    # Asking to destroy a message with a bogus ID should fail
    delete message_path(99999)
    assert_response :not_found
    assert_template "no_such_message"
  end
end
