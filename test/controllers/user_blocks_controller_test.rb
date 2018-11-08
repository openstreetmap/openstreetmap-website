require "test_helper"

class UserBlocksControllerTest < ActionController::TestCase
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

    get :index
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

    get :index
    assert_response :success
    assert_select "table#block_list", :count => 1 do
      assert_select "tr", :count => 21
    end

    get :index, :params => { :page => 2 }
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

    # Viewing a block should fail when no ID is given
    assert_raise ActionController::UrlGenerationError do
      get :show
    end

    # Viewing a block should fail when a bogus ID is given
    get :show, :params => { :id => 99999 }
    assert_response :not_found
    assert_template "not_found"
    assert_select "p", "Sorry, the user block with ID 99999 could not be found."

    # Viewing an expired block should work
    get :show, :params => { :id => expired_block.id }
    assert_response :success

    # Viewing a revoked block should work
    get :show, :params => { :id => revoked_block.id }
    assert_response :success

    # Viewing an active block should work, but shouldn't mark it as seen
    get :show, :params => { :id => active_block.id }
    assert_response :success
    assert_equal true, UserBlock.find(active_block.id).needs_view

    # Login as the blocked user
    session[:user] = active_block.user.id

    # Now viewing it should mark it as seen
    get :show, :params => { :id => active_block.id }
    assert_response :success
    assert_equal false, UserBlock.find(active_block.id).needs_view
  end

  ##
  # test the new action
  def test_new
    target_user = create(:user)

    # Check that the block creation page requires us to login
    get :new, :params => { :display_name => target_user.display_name }
    assert_redirected_to login_path(:referer => new_user_block_path(:display_name => target_user.display_name))

    # Login as a normal user
    session[:user] = create(:user).id

    # Check that normal users can't load the block creation page
    get :new, :params => { :display_name => target_user.display_name }
    assert_response :redirect
    assert_redirected_to :controller => "errors", :action => "forbidden"

    # Login as a moderator
    session[:user] = create(:moderator_user).id

    # Check that the block creation page loads for moderators
    get :new, :params => { :display_name => target_user.display_name }
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
    assert_template "users/no_such_user"
    assert_select "h1", "The user  does not exist"

    # We should get an error if the user doesn't exist
    get :new, :params => { :display_name => "non_existent_user" }
    assert_response :not_found
    assert_template "users/no_such_user"
    assert_select "h1", "The user non_existent_user does not exist"
  end

  ##
  # test the edit action
  def test_edit
    active_block = create(:user_block)

    # Check that the block edit page requires us to login
    get :edit, :params => { :id => active_block.id }
    assert_redirected_to login_path(:referer => edit_user_block_path(active_block))

    # Login as a normal user
    session[:user] = create(:user).id

    # Check that normal users can't load the block edit page
    get :edit, :params => { :id => active_block.id }
    assert_response :redirect
    assert_redirected_to :controller => "errors", :action => "forbidden"

    # Login as a moderator
    session[:user] = create(:moderator_user).id

    # Check that the block edit page loads for moderators
    get :edit, :params => { :id => active_block.id }
    assert_response :success
    assert_select "form#edit_user_block_#{active_block.id}", :count => 1 do
      assert_select "textarea#user_block_reason", :count => 1
      assert_select "select#user_block_period", :count => 1
      assert_select "input#user_block_needs_view[type='checkbox']", :count => 1
      assert_select "input[type='submit'][value='Update block']", :count => 1
    end

    # We should get an error if no user is specified
    assert_raise ActionController::UrlGenerationError do
      get :edit
    end

    # We should get an error if the user doesn't exist
    get :edit, :params => { :id => 99999 }
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
    post :create
    assert_response :forbidden

    # Login as a normal user
    session[:user] = create(:user).id

    # Check that normal users can't create blocks
    post :create
    assert_response :redirect
    assert_redirected_to :controller => "errors", :action => "forbidden"

    # Login as a moderator
    session[:user] = moderator_user.id

    # A bogus block period should result in an error
    assert_no_difference "UserBlock.count" do
      post :create,
           :params => { :display_name => target_user.display_name,
                        :user_block_period => "99" }
    end
    assert_redirected_to new_user_block_path(:display_name => target_user.display_name)
    assert_equal "The blocking period must be one of the values selectable in the drop-down list.", flash[:error]

    # Check that creating a block works
    assert_difference "UserBlock.count", 1 do
      post :create,
           :params => { :display_name => target_user.display_name,
                        :user_block_period => "12",
                        :user_block => { :needs_view => false, :reason => "Vandalism" } }
    end
    id = UserBlock.order(:id).ids.last
    assert_redirected_to user_block_path(:id => id)
    assert_equal "Created a block on user #{target_user.display_name}.", flash[:notice]
    b = UserBlock.find(id)
    assert_in_delta Time.now, b.created_at, 1
    assert_in_delta Time.now, b.updated_at, 1
    assert_in_delta Time.now + 12.hours, b.ends_at, 1
    assert_equal false, b.needs_view
    assert_equal "Vandalism", b.reason
    assert_equal "markdown", b.reason_format
    assert_equal moderator_user.id, b.creator_id

    # We should get an error if no user is specified
    post :create
    assert_response :not_found
    assert_template "users/no_such_user"
    assert_select "h1", "The user  does not exist"

    # We should get an error if the user doesn't exist
    post :create, :params => { :display_name => "non_existent_user" }
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
    put :update, :params => { :id => active_block.id }
    assert_response :forbidden

    # Login as a normal user
    session[:user] = create(:user).id

    # Check that normal users can't update blocks
    put :update, :params => { :id => active_block.id }
    assert_response :redirect
    assert_redirected_to :controller => "errors", :action => "forbidden"

    # Login as the wrong moderator
    session[:user] = second_moderator_user.id

    # Check that only the person who created a block can update it
    assert_no_difference "UserBlock.count" do
      put :update,
          :params => { :id => active_block.id,
                       :user_block_period => "12",
                       :user_block => { :needs_view => true, :reason => "Vandalism" } }
    end
    assert_redirected_to edit_user_block_path(active_block)
    assert_equal "Only the moderator who created this block can edit it.", flash[:error]

    # Login as the correct moderator
    session[:user] = moderator_user.id

    # A bogus block period should result in an error
    assert_no_difference "UserBlock.count" do
      put :update,
          :params => { :id => active_block.id,
                       :user_block_period => "99" }
    end
    assert_redirected_to edit_user_block_path(active_block)
    assert_equal "The blocking period must be one of the values selectable in the drop-down list.", flash[:error]

    # Check that updating a block works
    assert_no_difference "UserBlock.count" do
      put :update,
          :params => { :id => active_block.id,
                       :user_block_period => "12",
                       :user_block => { :needs_view => true, :reason => "Vandalism" } }
    end
    assert_redirected_to user_block_path(active_block)
    assert_equal "Block updated.", flash[:notice]
    b = UserBlock.find(active_block.id)
    assert_in_delta Time.now, b.updated_at, 1
    assert_equal true, b.needs_view
    assert_equal "Vandalism", b.reason

    # We should get an error if no block ID is specified
    assert_raise ActionController::UrlGenerationError do
      put :update
    end

    # We should get an error if the block doesn't exist
    put :update, :params => { :id => 99999 }
    assert_response :not_found
    assert_template "not_found"
    assert_select "p", "Sorry, the user block with ID 99999 could not be found."
  end

  ##
  # test the revoke action
  def test_revoke
    active_block = create(:user_block)

    # Check that the block revoke page requires us to login
    get :revoke, :params => { :id => active_block.id }
    assert_redirected_to login_path(:referer => revoke_user_block_path(:id => active_block.id))

    # Login as a normal user
    session[:user] = create(:user).id

    # Check that normal users can't load the block revoke page
    get :revoke, :params => { :id => active_block.id }
    assert_response :redirect
    assert_redirected_to :controller => "errors", :action => "forbidden"

    # Login as a moderator
    session[:user] = create(:moderator_user).id

    # Check that the block revoke page loads for moderators
    get :revoke, :params => { :id => active_block.id }
    assert_response :success
    assert_template "revoke"
    assert_select "form", :count => 1 do
      assert_select "input#confirm[type='checkbox']", :count => 1
      assert_select "input[type='submit'][value='Revoke!']", :count => 1
    end

    # Check that revoking a block works
    post :revoke, :params => { :id => active_block.id, :confirm => true }
    assert_redirected_to user_block_path(active_block)
    b = UserBlock.find(active_block.id)
    assert_in_delta Time.now, b.ends_at, 1

    # We should get an error if no block ID is specified
    assert_raise ActionController::UrlGenerationError do
      get :revoke
    end

    # We should get an error if the block doesn't exist
    get :revoke, :params => { :id => 99999 }
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

    # Asking for a list of blocks with no user name should fail
    assert_raise ActionController::UrlGenerationError do
      get :blocks_on
    end

    # Asking for a list of blocks with a bogus user name should fail
    get :blocks_on, :params => { :display_name => "non_existent_user" }
    assert_response :not_found
    assert_template "users/no_such_user"
    assert_select "h1", "The user non_existent_user does not exist"

    # Check the list of blocks for a user that has never been blocked
    get :blocks_on, :params => { :display_name => normal_user.display_name }
    assert_response :success
    assert_select "table#block_list", false
    assert_select "p", "#{normal_user.display_name} has not been blocked yet."

    # Check the list of blocks for a user that is currently blocked
    get :blocks_on, :params => { :display_name => blocked_user.display_name }
    assert_response :success
    assert_select "table#block_list", :count => 1 do
      assert_select "tr", 3
      assert_select "a[href='#{user_block_path(active_block)}']", 1
      assert_select "a[href='#{user_block_path(revoked_block)}']", 1
    end

    # Check the list of blocks for a user that has previously been blocked
    get :blocks_on, :params => { :display_name => unblocked_user.display_name }
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

    get :blocks_on, :params => { :display_name => user.display_name }
    assert_response :success
    assert_select "table#block_list", :count => 1 do
      assert_select "tr", :count => 21
    end

    get :blocks_on, :params => { :display_name => user.display_name, :page => 2 }
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

    # Asking for a list of blocks with no user name should fail
    assert_raise ActionController::UrlGenerationError do
      get :blocks_by
    end

    # Asking for a list of blocks with a bogus user name should fail
    get :blocks_by, :params => { :display_name => "non_existent_user" }
    assert_response :not_found
    assert_template "users/no_such_user"
    assert_select "h1", "The user non_existent_user does not exist"

    # Check the list of blocks given by one moderator
    get :blocks_by, :params => { :display_name => moderator_user.display_name }
    assert_response :success
    assert_select "table#block_list", :count => 1 do
      assert_select "tr", 2
      assert_select "a[href='#{user_block_path(active_block)}']", 1
    end

    # Check the list of blocks given by a different moderator
    get :blocks_by, :params => { :display_name => second_moderator_user.display_name }
    assert_response :success
    assert_select "table#block_list", :count => 1 do
      assert_select "tr", 3
      assert_select "a[href='#{user_block_path(expired_block)}']", 1
      assert_select "a[href='#{user_block_path(revoked_block)}']", 1
    end

    # Check the list of blocks (not) given by a normal user
    get :blocks_by, :params => { :display_name => normal_user.display_name }
    assert_response :success
    assert_select "table#block_list", false
    assert_select "p", "#{normal_user.display_name} has not made any blocks yet."
  end

  ##
  # test the blocks_by action with multiple pages
  def test_blocks_by_paged
    user = create(:moderator_user)
    create_list(:user_block, 50, :creator => user)

    get :blocks_by, :params => { :display_name => user.display_name }
    assert_response :success
    assert_select "table#block_list", :count => 1 do
      assert_select "tr", :count => 21
    end

    get :blocks_by, :params => { :display_name => user.display_name, :page => 2 }
    assert_response :success
    assert_select "table#block_list", :count => 1 do
      assert_select "tr", :count => 21
    end
  end
end
