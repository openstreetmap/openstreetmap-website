require "test_helper"

class UserBlocksControllerTest < ActionDispatch::IntegrationTest
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
    active_block = create(:user_block)
    expired_block = create(:user_block, :expired)
    revoked_block = create(:user_block, :revoked)

    get user_blocks_path
    assert_response :success
    assert_select "table#block_list", :count => 1 do
      assert_select "tr", 4
      assert_select "a[href='#{user_block_path(active_block)}']", 1
      assert_select "a[href='#{user_block_path(expired_block)}']", 1
      assert_select "a[href='#{user_block_path(revoked_block)}']", 1
    end
  end

  ##
  # test the index action with multiple pages
  def test_index_paged
    create_list(:user_block, 50)

    get user_blocks_path
    assert_response :success
    assert_select "table#block_list", :count => 1 do
      assert_select "tr", :count => 21
    end

    get user_blocks_path(:page => 2)
    assert_response :success
    assert_select "table#block_list", :count => 1 do
      assert_select "tr", :count => 21
    end
  end

  ##
  # test the show action
  def test_show
    active_block = create(:user_block, :needs_view)
    expired_block = create(:user_block, :expired)
    revoked_block = create(:user_block, :revoked)

    # Viewing a block should fail when a bogus ID is given
    get user_block_path(:id => 99999)
    assert_response :not_found
    assert_template "not_found"
    assert_select "p", "Sorry, the user block with ID 99999 could not be found."

    # Viewing an expired block should work
    get user_block_path(:id => expired_block)
    assert_response :success

    # Viewing a revoked block should work
    get user_block_path(:id => revoked_block)
    assert_response :success

    # Viewing an active block should work, but shouldn't mark it as seen
    get user_block_path(:id => active_block)
    assert_response :success
    assert UserBlock.find(active_block.id).needs_view

    # Login as the blocked user
    session_for(active_block.user)

    # Now viewing it should mark it as seen
    get user_block_path(:id => active_block)
    assert_response :success
    assert_not UserBlock.find(active_block.id).needs_view
  end

  ##
  # test the new action
  def test_new
    target_user = create(:user)

    # Check that the block creation page requires us to login
    get new_user_block_path(:display_name => target_user.display_name)
    assert_redirected_to login_path(:referer => new_user_block_path(:display_name => target_user.display_name))

    # Login as a normal user
    session_for(create(:user))

    # Check that normal users can't load the block creation page
    get new_user_block_path(:display_name => target_user.display_name)
    assert_response :redirect
    assert_redirected_to :controller => "errors", :action => "forbidden"

    # Login as a moderator
    session_for(create(:moderator_user))

    # Check that the block creation page loads for moderators
    get new_user_block_path(:display_name => target_user.display_name)
    assert_response :success
    assert_select "form#new_user_block", :count => 1 do
      assert_select "textarea#user_block_reason", :count => 1
      assert_select "select#user_block_period", :count => 1
      assert_select "input#user_block_needs_view[type='checkbox']", :count => 1
      assert_select "input#display_name[type='hidden']", :count => 1
      assert_select "input[type='submit'][value='Create block']", :count => 1
    end

    # We should get an error if the user doesn't exist
    get new_user_block_path(:display_name => "non_existent_user")
    assert_response :not_found
    assert_template "users/no_such_user"
    assert_select "h1", "The user non_existent_user does not exist"
  end

  ##
  # test the edit action
  def test_edit
    active_block = create(:user_block)

    # Check that the block edit page requires us to login
    get edit_user_block_path(:id => active_block)
    assert_redirected_to login_path(:referer => edit_user_block_path(active_block))

    # Login as a normal user
    session_for(create(:user))

    # Check that normal users can't load the block edit page
    get edit_user_block_path(:id => active_block)
    assert_response :redirect
    assert_redirected_to :controller => "errors", :action => "forbidden"

    # Login as a moderator
    session_for(create(:moderator_user))

    # Check that the block edit page loads for moderators
    get edit_user_block_path(:id => active_block)
    assert_response :success
    assert_select "form#edit_user_block_#{active_block.id}", :count => 1 do
      assert_select "textarea#user_block_reason", :count => 1
      assert_select "select#user_block_period", :count => 1
      assert_select "input#user_block_needs_view[type='checkbox']", :count => 1
      assert_select "input[type='submit'][value='Update block']", :count => 1
    end

    # We should get an error if the user doesn't exist
    get edit_user_block_path(:id => 99999)
    assert_response :not_found
    assert_template "not_found"
    assert_select "p", "Sorry, the user block with ID 99999 could not be found."
  end

  ##
  # test the create action
  def test_create
    target_user = create(:user)
    moderator_user = create(:moderator_user)

    # Not logged in yet, so creating a block should fail
    post user_blocks_path
    assert_response :forbidden

    # Login as a normal user
    session_for(create(:user))

    # Check that normal users can't create blocks
    post user_blocks_path
    assert_response :redirect
    assert_redirected_to :controller => "errors", :action => "forbidden"

    # Login as a moderator
    session_for(moderator_user)

    # A bogus block period should result in an error
    assert_no_difference "UserBlock.count" do
      post user_blocks_path(:display_name => target_user.display_name,
                            :user_block_period => "99")
    end
    assert_redirected_to new_user_block_path(:display_name => target_user.display_name)
    assert_equal "The blocking period must be one of the values selectable in the drop-down list.", flash[:error]

    # Check that creating a block works
    assert_difference "UserBlock.count", 1 do
      post user_blocks_path(:display_name => target_user.display_name,
                            :user_block_period => "12",
                            :user_block => { :needs_view => false, :reason => "Vandalism" })
    end
    id = UserBlock.order(:id).ids.last
    assert_redirected_to user_block_path(:id => id)
    assert_equal "Created a block on user #{target_user.display_name}.", flash[:notice]
    b = UserBlock.find(id)
    assert_in_delta Time.now.utc, b.created_at, 1
    assert_in_delta Time.now.utc, b.updated_at, 1
    assert_in_delta Time.now.utc + 12.hours, b.ends_at, 1
    assert_not b.needs_view
    assert_equal "Vandalism", b.reason
    assert_equal "markdown", b.reason_format
    assert_equal moderator_user.id, b.creator_id

    # We should get an error if no user is specified
    post user_blocks_path
    assert_response :not_found
    assert_template "users/no_such_user"
    assert_select "h1", "The user  does not exist"

    # We should get an error if the user doesn't exist
    post user_blocks_path(:display_name => "non_existent_user")
    assert_response :not_found
    assert_template "users/no_such_user"
    assert_select "h1", "The user non_existent_user does not exist"
  end

  ##
  # test the update action
  def test_update
    moderator_user = create(:moderator_user)
    second_moderator_user = create(:moderator_user)
    active_block = create(:user_block, :creator => moderator_user)

    # Not logged in yet, so updating a block should fail
    put user_block_path(:id => active_block)
    assert_response :forbidden

    # Login as a normal user
    session_for(create(:user))

    # Check that normal users can't update blocks
    put user_block_path(:id => active_block)
    assert_response :redirect
    assert_redirected_to :controller => "errors", :action => "forbidden"

    # Login as the wrong moderator
    session_for(second_moderator_user)

    # Check that only the person who created a block can update it
    assert_no_difference "UserBlock.count" do
      put user_block_path(:id => active_block,
                          :user_block_period => "12",
                          :user_block => { :needs_view => true, :reason => "Vandalism" })
    end
    assert_redirected_to edit_user_block_path(active_block)
    assert_equal "Only the moderator who created this block can edit it.", flash[:error]

    # Login as the correct moderator
    session_for(moderator_user)

    # A bogus block period should result in an error
    assert_no_difference "UserBlock.count" do
      put user_block_path(:id => active_block, :user_block_period => "99")
    end
    assert_redirected_to edit_user_block_path(active_block)
    assert_equal "The blocking period must be one of the values selectable in the drop-down list.", flash[:error]

    # Check that updating a block works
    assert_no_difference "UserBlock.count" do
      put user_block_path(:id => active_block,
                          :user_block_period => "12",
                          :user_block => { :needs_view => true, :reason => "Vandalism" })
    end
    assert_redirected_to user_block_path(active_block)
    assert_equal "Block updated.", flash[:notice]
    b = UserBlock.find(active_block.id)
    assert_in_delta Time.now.utc, b.updated_at, 1
    assert b.needs_view
    assert_equal "Vandalism", b.reason

    # We should get an error if the block doesn't exist
    put user_block_path(:id => 99999)
    assert_response :not_found
    assert_template "not_found"
    assert_select "p", "Sorry, the user block with ID 99999 could not be found."
  end

  ##
  # test the revoke action
  def test_revoke
    active_block = create(:user_block)

    # Check that the block revoke page requires us to login
    get revoke_user_block_path(:id => active_block)
    assert_redirected_to login_path(:referer => revoke_user_block_path(:id => active_block))

    # Login as a normal user
    session_for(create(:user))

    # Check that normal users can't load the block revoke page
    get revoke_user_block_path(:id => active_block)
    assert_response :redirect
    assert_redirected_to :controller => "errors", :action => "forbidden"

    # Login as a moderator
    session_for(create(:moderator_user))

    # Check that the block revoke page loads for moderators
    get revoke_user_block_path(:id => active_block)
    assert_response :success
    assert_template "revoke"
    assert_select "form", :count => 1 do
      assert_select "input#confirm[type='checkbox']", :count => 1
      assert_select "input[type='submit'][value='Revoke!']", :count => 1
    end

    # Check that revoking a block using GET should fail
    get revoke_user_block_path(:id => active_block, :confirm => true)
    assert_response :success
    assert_template "revoke"
    b = UserBlock.find(active_block.id)
    assert b.ends_at - Time.now.utc > 100

    # Check that revoking a block works using POST
    post revoke_user_block_path(:id => active_block, :confirm => true)
    assert_redirected_to user_block_path(active_block)
    b = UserBlock.find(active_block.id)
    assert_in_delta Time.now.utc, b.ends_at, 1

    # We should get an error if the block doesn't exist
    get revoke_user_block_path(:id => 99999)
    assert_response :not_found
    assert_template "not_found"
    assert_select "p", "Sorry, the user block with ID 99999 could not be found."
  end

  ##
  # test the blocks_on action
  def test_blocks_on
    blocked_user = create(:user)
    unblocked_user = create(:user)
    normal_user = create(:user)
    active_block = create(:user_block, :user => blocked_user)
    revoked_block = create(:user_block, :revoked, :user => blocked_user)
    expired_block = create(:user_block, :expired, :user => unblocked_user)

    # Asking for a list of blocks with a bogus user name should fail
    get user_blocks_on_path(:display_name => "non_existent_user")
    assert_response :not_found
    assert_template "users/no_such_user"
    assert_select "h1", "The user non_existent_user does not exist"

    # Check the list of blocks for a user that has never been blocked
    get user_blocks_on_path(:display_name => normal_user.display_name)
    assert_response :success
    assert_select "table#block_list", false
    assert_select "p", "#{normal_user.display_name} has not been blocked yet."

    # Check the list of blocks for a user that is currently blocked
    get user_blocks_on_path(:display_name => blocked_user.display_name)
    assert_response :success
    assert_select "table#block_list", :count => 1 do
      assert_select "tr", 3
      assert_select "a[href='#{user_block_path(active_block)}']", 1
      assert_select "a[href='#{user_block_path(revoked_block)}']", 1
    end

    # Check the list of blocks for a user that has previously been blocked
    get user_blocks_on_path(:display_name => unblocked_user.display_name)
    assert_response :success
    assert_select "table#block_list", :count => 1 do
      assert_select "tr", 2
      assert_select "a[href='#{user_block_path(expired_block)}']", 1
    end
  end

  ##
  # test the blocks_on action with multiple pages
  def test_blocks_on_paged
    user = create(:user)
    create_list(:user_block, 50, :user => user)

    get user_blocks_on_path(:display_name => user.display_name)
    assert_response :success
    assert_select "table#block_list", :count => 1 do
      assert_select "tr", :count => 21
    end

    get user_blocks_on_path(:display_name => user.display_name, :page => 2)
    assert_response :success
    assert_select "table#block_list", :count => 1 do
      assert_select "tr", :count => 21
    end
  end

  ##
  # test the blocks_by action
  def test_blocks_by
    moderator_user = create(:moderator_user)
    second_moderator_user = create(:moderator_user)
    normal_user = create(:user)
    active_block = create(:user_block, :creator => moderator_user)
    expired_block = create(:user_block, :expired, :creator => second_moderator_user)
    revoked_block = create(:user_block, :revoked, :creator => second_moderator_user)

    # Asking for a list of blocks with a bogus user name should fail
    get user_blocks_by_path(:display_name => "non_existent_user")
    assert_response :not_found
    assert_template "users/no_such_user"
    assert_select "h1", "The user non_existent_user does not exist"

    # Check the list of blocks given by one moderator
    get user_blocks_by_path(:display_name => moderator_user.display_name)
    assert_response :success
    assert_select "table#block_list", :count => 1 do
      assert_select "tr", 2
      assert_select "a[href='#{user_block_path(active_block)}']", 1
    end

    # Check the list of blocks given by a different moderator
    get user_blocks_by_path(:display_name => second_moderator_user.display_name)
    assert_response :success
    assert_select "table#block_list", :count => 1 do
      assert_select "tr", 3
      assert_select "a[href='#{user_block_path(expired_block)}']", 1
      assert_select "a[href='#{user_block_path(revoked_block)}']", 1
    end

    # Check the list of blocks (not) given by a normal user
    get user_blocks_by_path(:display_name => normal_user.display_name)
    assert_response :success
    assert_select "table#block_list", false
    assert_select "p", "#{normal_user.display_name} has not made any blocks yet."
  end

  ##
  # test the blocks_by action with multiple pages
  def test_blocks_by_paged
    user = create(:moderator_user)
    create_list(:user_block, 50, :creator => user)

    get user_blocks_by_path(:display_name => user.display_name)
    assert_response :success
    assert_select "table#block_list", :count => 1 do
      assert_select "tr", :count => 21
    end

    get user_blocks_by_path(:display_name => user.display_name, :page => 2)
    assert_response :success
    assert_select "table#block_list", :count => 1 do
      assert_select "tr", :count => 21
    end
  end
end
