require File.dirname(__FILE__) + '/../test_helper'

class UserBlocksControllerTest < ActionController::TestCase
  fixtures :users, :user_roles, :user_blocks

  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/blocks/new/username", :method => :get },
      { :controller => "user_blocks", :action => "new", :display_name => "username" }
    )

    assert_routing(
      { :path => "/user_blocks", :method => :get },
      { :controller => "user_blocks", :action => "index" }
    )
    assert_routing(
      { :path => "/user_blocks/new", :method => :get },
      { :controller => "user_blocks", :action => "new" }
    )
    assert_routing(
      { :path => "/user_blocks", :method => :post },
      { :controller => "user_blocks", :action => "create" }
    )
    assert_routing(
      { :path => "/user_blocks/1", :method => :get },
      { :controller => "user_blocks", :action => "show", :id => "1" }
    )
    assert_routing(
      { :path => "/user_blocks/1/edit", :method => :get },
      { :controller => "user_blocks", :action => "edit", :id => "1" }
    )
    assert_routing(
      { :path => "/user_blocks/1", :method => :put },
      { :controller => "user_blocks", :action => "update", :id => "1" }
    )
    assert_routing(
      { :path => "/user_blocks/1", :method => :delete },
      { :controller => "user_blocks", :action => "destroy", :id => "1" }
    )
    assert_routing(
      { :path => "/blocks/1/revoke", :method => :get },
      { :controller => "user_blocks", :action => "revoke", :id => "1" }
    )
    assert_routing(
      { :path => "/blocks/1/revoke", :method => :post },
      { :controller => "user_blocks", :action => "revoke", :id => "1" }
    )

    assert_routing(
      { :path => "/user/username/blocks", :method => :get },
      { :controller => "user_blocks", :action => "blocks_on", :display_name => "username" }
    )
    assert_routing(
      { :path => "/user/username/blocks_by", :method => :get },
      { :controller => "user_blocks", :action => "blocks_by", :display_name => "username" }
    )
  end

  ##
  # test the index action
  def test_index
    # The list of blocks should load
    get :index
    assert_response :success
    assert_select "table#block_list", :count => 1 do
      assert_select "tr", 4
      assert_select "a[href='#{user_block_path(user_blocks(:active_block))}']", 1
      assert_select "a[href='#{user_block_path(user_blocks(:expired_block))}']", 1
      assert_select "a[href='#{user_block_path(user_blocks(:revoked_block))}']", 1
    end
  end

  ##
  # test the show action
  def test_show
    # Viewing a block should fail when no ID is given
    get :show
    assert_response :not_found
    assert_template "not_found"
    assert_select "p", "Sorry, the user block with ID  could not be found."

    # Viewing a block should fail when a bogus ID is given
    get :show, :id => 99999
    assert_response :not_found
    assert_template "not_found"
    assert_select "p", "Sorry, the user block with ID 99999 could not be found."

    # Viewing an expired block should work
    get :show, :id => user_blocks(:expired_block)
    assert_response :success

    # Viewing a revoked block should work
    get :show, :id => user_blocks(:revoked_block)
    assert_response :success

    # Viewing an active block should work, but shouldn't mark it as seen
    get :show, :id => user_blocks(:active_block)
    assert_response :success
    assert_equal true, UserBlock.find(user_blocks(:active_block).id).needs_view

    # Login as the blocked user
    session[:user] = users(:blocked_user).id
    cookies["_osm_username"] = users(:blocked_user).display_name

    # Now viewing it should mark it as seen
    get :show, :id => user_blocks(:active_block)
    assert_response :success
    assert_equal false, UserBlock.find(user_blocks(:active_block).id).needs_view
  end

  ##
  # test the new action
  def test_new
    # Check that the block creation page requires us to login
    get :new, :display_name => users(:normal_user).display_name
    assert_redirected_to login_path(:referer => new_user_block_path(:display_name => users(:normal_user).display_name))

    # Login as a normal user
    session[:user] = users(:public_user).id
    cookies["_osm_username"] = users(:public_user).display_name

    # Check that normal users can't load the block creation page
    get :new, :display_name => users(:normal_user).display_name
    assert_redirected_to user_blocks_path
    assert_equal "You need to be a moderator to perform that action.", flash[:error]

    # Login as a moderator
    session[:user] = users(:moderator_user).id
    cookies["_osm_username"] = users(:moderator_user).display_name

    # Check that the block creation page loads for moderators
    get :new, :display_name => users(:normal_user).display_name
    assert_response :success
    assert_select "form#new_user_block", :count => 1 do
      assert_select "textarea#user_block_reason", :count => 1
      assert_select "select#user_block_period", :count => 1
      assert_select "input#user_block_needs_view[type='checkbox']", :count => 1
      assert_select "input#display_name[type='hidden']", :count => 1
      assert_select "input[type='submit'][value='Create block']", :count => 1
    end

    # We should get an error if no user is specified
    get :new
    assert_response :not_found
    assert_template "user/no_such_user"
    assert_select "h2", "The user  does not exist"

    # We should get an error if the user doesn't exist
    get :new, :display_name => "non_existent_user"
    assert_response :not_found
    assert_template "user/no_such_user"
    assert_select "h2", "The user non_existent_user does not exist"
  end

  ##
  # test the edit action
  def test_edit
    # Check that the block edit page requires us to login
    get :edit, :id => user_blocks(:active_block).id
    assert_redirected_to login_path(:referer => edit_user_block_path(:id => user_blocks(:active_block).id))

    # Login as a normal user
    session[:user] = users(:public_user).id
    cookies["_osm_username"] = users(:public_user).display_name

    # Check that normal users can't load the block edit page
    get :edit, :id => user_blocks(:active_block).id
    assert_redirected_to user_blocks_path
    assert_equal "You need to be a moderator to perform that action.", flash[:error]

    # Login as a moderator
    session[:user] = users(:moderator_user).id
    cookies["_osm_username"] = users(:moderator_user).display_name

    # Check that the block edit page loads for moderators
    get :edit, :id => user_blocks(:active_block).id
    assert_response :success
    assert_select "form#edit_user_block_#{user_blocks(:active_block).id}", :count => 1 do
      assert_select "textarea#user_block_reason", :count => 1
      assert_select "select#user_block_period", :count => 1
      assert_select "input#user_block_needs_view[type='checkbox']", :count => 1
      assert_select "input[type='submit'][value='Update block']", :count => 1
    end

    # We should get an error if no user is specified
    get :edit
    assert_response :not_found
    assert_template "not_found"
    assert_select "p", "Sorry, the user block with ID  could not be found."

    # We should get an error if the user doesn't exist
    get :edit, :id => 99999
    assert_response :not_found
    assert_template "not_found"
    assert_select "p", "Sorry, the user block with ID 99999 could not be found."
  end

  ##
  # test the create action
  def test_create
    # Not logged in yet, so creating a block should fail
    post :create
    assert_response :forbidden

    # Login as a normal user
    session[:user] = users(:public_user).id
    cookies["_osm_username"] = users(:public_user).display_name

    # Check that normal users can't create blocks
    post :create
    assert_response :forbidden

    # Login as a moderator
    session[:user] = users(:moderator_user).id
    cookies["_osm_username"] = users(:moderator_user).display_name

    # A bogus block period should result in an error
    assert_no_difference "UserBlock.count" do
      post :create,
        :display_name => users(:unblocked_user).display_name,
        :user_block_period => "99"
    end
    assert_redirected_to new_user_block_path(:display_name => users(:unblocked_user).display_name)
    assert_equal "The blocking period must be one of the values selectable in the drop-down list.", flash[:error]

    # Check that creating a block works
    assert_difference "UserBlock.count", 1 do
      post :create,
        :display_name => users(:unblocked_user).display_name,
        :user_block_period => "12",
        :user_block => { :needs_view => false, :reason => "Vandalism" }
    end
    assert_redirected_to user_block_path(:id => 4)
    assert_equal "Created a block on user #{users(:unblocked_user).display_name}.", flash[:notice]
    b = UserBlock.find(4)
    assert_in_delta Time.now, b.created_at, 1
    assert_in_delta Time.now, b.updated_at, 1
    assert_in_delta Time.now + 12.hour, b.ends_at, 1
    assert_equal false, b.needs_view
    assert_equal "Vandalism", b.reason
    assert_equal "markdown", b.reason_format
    assert_equal users(:moderator_user).id, b.creator_id

    # We should get an error if no user is specified
    post :create
    assert_response :not_found
    assert_template "user/no_such_user"
    assert_select "h2", "The user  does not exist"

    # We should get an error if the user doesn't exist
    post :create, :display_name => "non_existent_user"
    assert_response :not_found
    assert_template "user/no_such_user"
    assert_select "h2", "The user non_existent_user does not exist"
  end

  ##
  # test the update action
  def test_update
    # Not logged in yet, so updating a block should fail
    put :update
    assert_response :forbidden

    # Login as a normal user
    session[:user] = users(:public_user).id
    cookies["_osm_username"] = users(:public_user).display_name

    # Check that normal users can't update blocks
    put :update
    assert_response :forbidden

    # Login as the wrong moderator
    session[:user] = users(:second_moderator_user).id
    cookies["_osm_username"] = users(:second_moderator_user).display_name

    # Check that only the person who created a block can update it
    assert_no_difference "UserBlock.count" do
      put :update,
        :id => user_blocks(:active_block).id,
        :user_block_period => "12",
        :user_block => { :needs_view => true, :reason => "Vandalism" }
    end
    assert_redirected_to edit_user_block_path(:id => user_blocks(:active_block).id)
    assert_equal "Only the moderator who created this block can edit it.", flash[:error]

    # Login as the correct moderator
    session[:user] = users(:moderator_user).id
    cookies["_osm_username"] = users(:moderator_user).display_name

    # A bogus block period should result in an error
    assert_no_difference "UserBlock.count" do
      put :update,
        :id => user_blocks(:active_block).id,
        :user_block_period => "99"
    end
    assert_redirected_to edit_user_block_path(:id => user_blocks(:active_block).id)
    assert_equal "The blocking period must be one of the values selectable in the drop-down list.", flash[:error]

    # Check that updating a block works
    assert_no_difference "UserBlock.count" do
      put :update,
        :id => user_blocks(:active_block).id,
        :user_block_period => "12",
        :user_block => { :needs_view => true, :reason => "Vandalism" }
    end
    assert_redirected_to user_block_path(:id => user_blocks(:active_block).id)
    assert_equal "Block updated.", flash[:notice]
    b = UserBlock.find(user_blocks(:active_block).id)
    assert_in_delta Time.now, b.updated_at, 1
    assert_equal true, b.needs_view
    assert_equal "Vandalism", b.reason

    # We should get an error if no block ID is specified
    put :update
    assert_response :not_found
    assert_template "not_found"
    assert_select "p", "Sorry, the user block with ID  could not be found."

    # We should get an error if the block doesn't exist
    put :update, :id => 99999
    assert_response :not_found
    assert_template "not_found"
    assert_select "p", "Sorry, the user block with ID 99999 could not be found."
  end

  ##
  # test the revoke action
  def test_revoke
    # Check that the block revoke page requires us to login
    get :revoke, :id => user_blocks(:active_block).id
    assert_redirected_to login_path(:referer => revoke_user_block_path(:id => user_blocks(:active_block).id))

    # Login as a normal user
    session[:user] = users(:public_user).id
    cookies["_osm_username"] = users(:public_user).display_name

    # Check that normal users can't load the block revoke page
    get :revoke, :id => user_blocks(:active_block).id
    assert_redirected_to user_blocks_path
    assert_equal "You need to be a moderator to perform that action.", flash[:error]

    # Login as a moderator
    session[:user] = users(:moderator_user).id
    cookies["_osm_username"] = users(:moderator_user).display_name

    # Check that the block revoke page loads for moderators
    get :revoke, :id => user_blocks(:active_block).id
    assert_response :success
    assert_template "revoke"
    assert_select "form", :count => 1 do
      assert_select "input#confirm[type='checkbox']", :count => 1
      assert_select "input[type='submit'][value='Revoke!']", :count => 1
    end

    # Check that revoking a block works
    post :revoke, :id => user_blocks(:active_block).id, :confirm => true
    assert_redirected_to user_block_path(:id => user_blocks(:active_block).id)
    b = UserBlock.find(user_blocks(:active_block).id)
    assert_in_delta Time.now, b.ends_at, 1

    # We should get an error if no block ID is specified
    get :revoke
    assert_response :not_found
    assert_template "not_found"
    assert_select "p", "Sorry, the user block with ID  could not be found."

    # We should get an error if the block doesn't exist
    get :revoke, :id => 99999
    assert_response :not_found
    assert_template "not_found"
    assert_select "p", "Sorry, the user block with ID 99999 could not be found."
  end

  ##
  # test the blocks_on action
  def test_blocks_on
    # Asking for a list of blocks with no user name should fail
    get :blocks_on
    assert_response :not_found
    assert_template "user/no_such_user"
    assert_select "h2", "The user  does not exist"

    # Asking for a list of blocks with a bogus user name should fail
    get :blocks_on, :display_name => "non_existent_user"
    assert_response :not_found
    assert_template "user/no_such_user"
    assert_select "h2", "The user non_existent_user does not exist"

    # Check the list of blocks for a user that has never been blocked
    get :blocks_on, :display_name => users(:normal_user).display_name
    assert_response :success
    assert_select "table#block_list", false
    assert_select "p", "#{users(:normal_user).display_name} has not been blocked yet."

    # Check the list of blocks for a user that is currently blocked
    get :blocks_on, :display_name => users(:blocked_user).display_name
    assert_response :success
    assert_select "table#block_list", :count => 1 do
      assert_select "tr", 3
      assert_select "a[href='#{user_block_path(user_blocks(:active_block))}']", 1
      assert_select "a[href='#{user_block_path(user_blocks(:revoked_block))}']", 1
    end

    # Check the list of blocks for a user that has previously been blocked
    get :blocks_on, :display_name => users(:unblocked_user).display_name
    assert_response :success
    assert_select "table#block_list", :count => 1 do
      assert_select "tr", 2
      assert_select "a[href='#{user_block_path(user_blocks(:expired_block))}']", 1
    end
  end

  ##
  # test the blocks_by action
  def test_blocks_by
    # Asking for a list of blocks with no user name should fail
    get :blocks_by
    assert_response :not_found
    assert_template "user/no_such_user"
    assert_select "h2", "The user  does not exist"

    # Asking for a list of blocks with a bogus user name should fail
    get :blocks_by, :display_name => "non_existent_user"
    assert_response :not_found
    assert_template "user/no_such_user"
    assert_select "h2", "The user non_existent_user does not exist"

    # Check the list of blocks given by one moderator
    get :blocks_by, :display_name => users(:moderator_user).display_name
    assert_response :success
    assert_select "table#block_list", :count => 1 do
      assert_select "tr", 2
      assert_select "a[href='#{user_block_path(user_blocks(:active_block))}']", 1
    end

    # Check the list of blocks given by a different moderator
    get :blocks_by, :display_name => users(:second_moderator_user).display_name
    assert_response :success
    assert_select "table#block_list", :count => 1 do
      assert_select "tr", 3
      assert_select "a[href='#{user_block_path(user_blocks(:expired_block))}']", 1
      assert_select "a[href='#{user_block_path(user_blocks(:revoked_block))}']", 1
    end

    # Check the list of blocks (not) given by a normal user
    get :blocks_by, :display_name => users(:normal_user).display_name
    assert_response :success
    assert_select "table#block_list", false
    assert_select "p", "#{users(:normal_user).display_name} has not made any blocks yet."
  end
end
