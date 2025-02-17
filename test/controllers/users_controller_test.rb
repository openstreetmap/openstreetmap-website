require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/user/new", :method => :get },
      { :controller => "users", :action => "new" }
    )

    assert_routing(
      { :path => "/user", :method => :post },
      { :controller => "users", :action => "create" }
    )

    assert_routing(
      { :path => "/user/go_public", :method => :post },
      { :controller => "users", :action => "go_public" }
    )

    assert_routing(
      { :path => "/user/suspended", :method => :get },
      { :controller => "users", :action => "suspended" }
    )

    assert_routing(
      { :path => "/user/username", :method => :get },
      { :controller => "users", :action => "show", :display_name => "username" }
    )
  end

  # The user creation page loads
  def test_new
    get new_user_path
    assert_redirected_to new_user_path(:cookie_test => "true")

    get new_user_path, :params => { :cookie_test => "true" }
    assert_response :success

    assert_no_match(/img-src \* data:;/, @response.headers["Content-Security-Policy-Report-Only"])

    assert_select "html", :count => 1 do
      assert_select "head", :count => 1 do
        assert_select "title", :text => /Sign Up/, :count => 1
      end
      assert_select "body", :count => 1 do
        assert_select "div#content", :count => 1 do
          assert_select "form[action='/user'][method='post']", :count => 1 do
            assert_select "input[id='user_email']", :count => 1
            assert_select "input[id='user_display_name']", :count => 1
            assert_select "input[id='user_pass_crypt'][type='password']", :count => 1
            assert_select "input[id='user_pass_crypt_confirmation'][type='password']", :count => 1
            assert_select "input[type='submit'][value='Sign Up']", :count => 1
          end
        end
      end
    end
  end

  def test_new_logged_in
    session_for(create(:user))

    get new_user_path
    assert_redirected_to root_path

    get new_user_path, :params => { :referer => "/test" }
    assert_redirected_to "/test"
  end

  def test_create_success
    user = build(:user, :pending)

    assert_difference "User.count", 1 do
      assert_difference "ActionMailer::Base.deliveries.size", 1 do
        perform_enqueued_jobs do
          post users_path, :params => { :user => user.attributes }
        end
      end
    end

    # Check the e-mail
    register_email = ActionMailer::Base.deliveries.first

    assert_equal register_email.to[0], user.email
    assert_match(/#{@url}/, register_email.body.to_s)

    # Check the page
    assert_redirected_to :controller => :confirmations, :action => :confirm, :display_name => user.display_name
  end

  def test_create_duplicate_email
    user = build(:user, :pending)
    create(:user, :email => user.email)

    assert_no_difference "User.count" do
      assert_no_difference "ActionMailer::Base.deliveries.size" do
        perform_enqueued_jobs do
          post users_path, :params => { :user => user.attributes }
        end
      end
    end

    assert_response :success
    assert_template "new"
    assert_select "form > div > input.is-invalid#user_email"
  end

  def test_create_duplicate_email_uppercase
    user = build(:user, :pending)
    create(:user, :email => user.email.upcase)

    assert_no_difference "User.count" do
      assert_no_difference "ActionMailer::Base.deliveries.size" do
        perform_enqueued_jobs do
          post users_path, :params => { :user => user.attributes }
        end
      end
    end

    assert_response :success
    assert_template "new"
    assert_select "form > div > input.is-invalid#user_email"
  end

  def test_create_duplicate_name
    user = build(:user, :pending)
    create(:user, :display_name => user.display_name)

    assert_no_difference "User.count" do
      assert_no_difference "ActionMailer::Base.deliveries.size" do
        perform_enqueued_jobs do
          post users_path, :params => { :user => user.attributes }
        end
      end
    end

    assert_response :success
    assert_template "new"
    assert_select "form > div > input.is-invalid#user_display_name"
  end

  def test_create_duplicate_name_uppercase
    user = build(:user, :pending)
    create(:user, :display_name => user.display_name.upcase)

    assert_no_difference "User.count" do
      assert_no_difference "ActionMailer::Base.deliveries.size" do
        perform_enqueued_jobs do
          post users_path, :params => { :user => user.attributes }
        end
      end
    end

    assert_response :success
    assert_template "new"
    assert_select "form > div > input.is-invalid#user_display_name"
  end

  def test_create_blocked_domain
    user = build(:user, :pending, :email => "user@example.net")

    # Now block that domain
    create(:acl, :domain => "example.net", :k => "no_account_creation")

    # Check that the second half of registration fails
    assert_no_difference "User.count" do
      assert_no_difference "ActionMailer::Base.deliveries.size" do
        perform_enqueued_jobs do
          post users_path, :params => { :user => user.attributes }
        end
      end
    end

    assert_response :success
    assert_template "blocked"
  end

  def test_create_referer_params
    user = build(:user, :pending)

    assert_difference "User.count", 1 do
      assert_difference "ActionMailer::Base.deliveries.size", 1 do
        post users_path, :params => { :user => user.attributes, :referer => "/edit?editor=id#map=1/2/3" }
        assert_enqueued_with :job => ActionMailer::MailDeliveryJob,
                             :args => proc { |args| args[3][:args][2] == welcome_path(:editor => "id", :zoom => 1, :lat => 2, :lon => 3) }
        perform_enqueued_jobs
      end
    end
  end

  def test_go_public
    user = create(:user, :data_public => false)
    session_for(user)

    post user_go_public_path

    assert_redirected_to account_path
    assert User.find(user.id).data_public
  end

  # Check that the user account page will display and contains some relevant
  # information for the user
  def test_show
    # Test a non-existent user
    get user_path("unknown")
    assert_response :not_found

    # Test a normal user
    user = create(:user)

    get user_path(user)
    assert_response :success
    assert_match(/img-src \* data:;/, @response.headers["Content-Security-Policy-Report-Only"])
    assert_select "div.content-heading" do
      assert_select "a[href^='/user/#{ERB::Util.u(user.display_name)}/history']", 1
      assert_select "a[href='/user/#{ERB::Util.u(user.display_name)}/traces']", 1
      assert_select "a[href='/user/#{ERB::Util.u(user.display_name)}/diary']", 1
      assert_select "a[href='/user/#{ERB::Util.u(user.display_name)}/diary_comments']", 1
      assert_select "a[href='/user/#{ERB::Util.u(user.display_name)}/account']", 0
      assert_select "a[href='/user/#{ERB::Util.u(user.display_name)}/blocks']", 0
      assert_select "a[href='/user/#{ERB::Util.u(user.display_name)}/blocks_by']", 0
      assert_select "a[href='/user_blocks/new/#{ERB::Util.u(user.display_name)}']", 0
    end

    # Test a user who has been blocked
    blocked_user = create(:user)
    create(:user_block, :user => blocked_user)
    get user_path(blocked_user)
    assert_response :success
    assert_select "div.content-heading" do
      assert_select "a[href^='/user/#{ERB::Util.u(blocked_user.display_name)}/history']", 1
      assert_select "a[href='/user/#{ERB::Util.u(blocked_user.display_name)}/traces']", 1
      assert_select "a[href='/user/#{ERB::Util.u(blocked_user.display_name)}/diary']", 1
      assert_select "a[href='/user/#{ERB::Util.u(blocked_user.display_name)}/diary_comments']", 1
      assert_select "a[href='/user/#{ERB::Util.u(blocked_user.display_name)}/account']", 0
      assert_select "a[href='/user/#{ERB::Util.u(blocked_user.display_name)}/blocks']", 1
      assert_select "a[href='/user/#{ERB::Util.u(blocked_user.display_name)}/blocks_by']", 0
      assert_select "a[href='/user_blocks/new/#{ERB::Util.u(blocked_user.display_name)}']", 0
    end

    # Test a moderator who has applied blocks
    moderator_user = create(:moderator_user)
    create(:user_block, :creator => moderator_user)
    get user_path(moderator_user)
    assert_response :success
    assert_select "div.content-heading" do
      assert_select "a[href^='/user/#{ERB::Util.u(moderator_user.display_name)}/history']", 1
      assert_select "a[href='/user/#{ERB::Util.u(moderator_user.display_name)}/traces']", 1
      assert_select "a[href='/user/#{ERB::Util.u(moderator_user.display_name)}/diary']", 1
      assert_select "a[href='/user/#{ERB::Util.u(moderator_user.display_name)}/diary_comments']", 1
      assert_select "a[href='/account']", 0
      assert_select "a[href='/user/#{ERB::Util.u(moderator_user.display_name)}/blocks']", 0
      assert_select "a[href='/user/#{ERB::Util.u(moderator_user.display_name)}/blocks_by']", 1
      assert_select "a[href='/user_blocks/new/#{ERB::Util.u(moderator_user.display_name)}']", 0
    end

    # Login as a normal user
    session_for(user)

    # Test the normal user
    get user_path(user)
    assert_response :success
    assert_select "div.content-heading" do
      assert_select "a[href^='/user/#{ERB::Util.u(user.display_name)}/history']", 1
      assert_select "a[href='/traces/mine']", 1
      assert_select "a[href='/user/#{ERB::Util.u(user.display_name)}/diary']", 1
      assert_select "a[href='/user/#{ERB::Util.u(user.display_name)}/diary_comments']", 1
      assert_select "a[href='/account']", 1
      assert_select "a[href='/user/#{ERB::Util.u(user.display_name)}/blocks']", 0
      assert_select "a[href='/user/#{ERB::Util.u(user.display_name)}/blocks_by']", 0
      assert_select "a[href='/user_blocks/new/#{ERB::Util.u(user.display_name)}']", 0
      assert_select "a[href='/api/0.6/user/#{ERB::Util.u(user.id)}']", 0
    end

    # Login as a moderator
    session_for(create(:moderator_user))

    # Test the normal user
    get user_path(user)
    assert_response :success
    assert_select "div.content-heading" do
      assert_select "a[href^='/user/#{ERB::Util.u(user.display_name)}/history']", 1
      assert_select "a[href='/user/#{ERB::Util.u(user.display_name)}/traces']", 1
      assert_select "a[href='/user/#{ERB::Util.u(user.display_name)}/diary']", 1
      assert_select "a[href='/user/#{ERB::Util.u(user.display_name)}/diary_comments']", 1
      assert_select "a[href='/account']", 0
      assert_select "a[href='/user/#{ERB::Util.u(user.display_name)}/blocks']", 0
      assert_select "a[href='/user/#{ERB::Util.u(user.display_name)}/blocks_by']", 0
      assert_select "a[href='/user_blocks/new/#{ERB::Util.u(user.display_name)}']", 1
      assert_select "a[href='/api/0.6/user/#{ERB::Util.u(user.id)}']", 1
    end
  end

  # Test whether information about contributor terms is shown for users who haven't agreed
  def test_terms_not_agreed
    agreed_user = create(:user, :terms_agreed => 3.days.ago)
    seen_user = create(:user, :terms_seen => true, :terms_agreed => nil)
    not_seen_user = create(:user, :terms_seen => false, :terms_agreed => nil)

    get user_path(agreed_user)
    assert_response :success
    assert_select "div.content-heading" do
      assert_select "dt", :count => 0, :text => /Contributor terms/
    end

    get user_path(seen_user)
    assert_response :success
    assert_select "div.content-heading" do
      assert_select "dt", :count => 1, :text => /Contributor terms/
      assert_select "dd", /Declined/
    end

    get user_path(not_seen_user)
    assert_response :success
    assert_select "div.content-heading" do
      assert_select "dt", :count => 1, :text => /Contributor terms/
      assert_select "dd", /Undecided/
    end
  end

  def test_auth_failure_callback
    get auth_failure_path
    assert_redirected_to login_path

    get auth_failure_path, :params => { :origin => "/" }
    assert_redirected_to root_path

    get auth_failure_path, :params => { :origin => "http://www.google.com" }
    assert_redirected_to login_path
  end
end
