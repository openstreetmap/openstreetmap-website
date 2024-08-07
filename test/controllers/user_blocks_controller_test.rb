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
    assert_routing(
      { :path => "/user/username/blocks/revoke_all", :method => :get },
      { :controller => "user_blocks", :action => "revoke_all", :display_name => "username" }
    )
    assert_routing(
      { :path => "/user/username/blocks/revoke_all", :method => :post },
      { :controller => "user_blocks", :action => "revoke_all", :display_name => "username" }
    )
  end

  ##
  # test the index action
  def test_index
    revoked_block = create(:user_block, :revoked)

    get user_blocks_path
    assert_response :success
    assert_select "table#block_list tbody tr", :count => 1 do
      assert_select "a[href='#{user_path revoked_block.user}']", :text => revoked_block.user.display_name
      assert_select "a[href='#{user_path revoked_block.creator}']", :text => revoked_block.creator.display_name
      assert_select "a[href='#{user_path revoked_block.revoker}']", :text => revoked_block.revoker.display_name
    end

    active_block = create(:user_block)
    expired_block = create(:user_block, :expired)

    get user_blocks_path
    assert_response :success
    assert_select "table#block_list tbody", :count => 1 do
      assert_select "tr", 3
      assert_select "a[href='#{user_block_path(active_block)}']", 1
      assert_select "a[href='#{user_block_path(expired_block)}']", 1
      assert_select "a[href='#{user_block_path(revoked_block)}']", 1
    end
  end

  ##
  # test the index action with multiple pages
  def test_index_paged
    user_blocks = create_list(:user_block, 50).reverse
    next_path = user_blocks_path

    get next_path
    assert_response :success
    check_user_blocks_table user_blocks[0...20]
    check_no_page_link "Newer Blocks"
    next_path = check_page_link "Older Blocks"

    get next_path
    assert_response :success
    check_user_blocks_table user_blocks[20...40]
    check_page_link "Newer Blocks"
    next_path = check_page_link "Older Blocks"

    get next_path
    assert_response :success
    check_user_blocks_table user_blocks[40...50]
    check_page_link "Newer Blocks"
    check_no_page_link "Older Blocks"
  end

  ##
  # test the index action with invalid pages
  def test_index_invalid_paged
    %w[-1 0 fred].each do |id|
      get user_blocks_path(:before => id)
      assert_redirected_to :controller => :errors, :action => :bad_request

      get user_blocks_path(:after => id)
      assert_redirected_to :controller => :errors, :action => :bad_request
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
    assert_select "h1 a[href='#{user_path expired_block.user}']", :text => expired_block.user.display_name
    assert_select "h1 a[href='#{user_path expired_block.creator}']", :text => expired_block.creator.display_name

    # Viewing a revoked block should work
    get user_block_path(:id => revoked_block)
    assert_response :success
    assert_select "h1 a[href='#{user_path revoked_block.user}']", :text => revoked_block.user.display_name
    assert_select "h1 a[href='#{user_path revoked_block.creator}']", :text => revoked_block.creator.display_name
    assert_select "a[href='#{user_path revoked_block.revoker}']", :text => revoked_block.revoker.display_name

    # Viewing an active block should work, but shouldn't mark it as seen
    get user_block_path(:id => active_block)
    assert_response :success
    assert_select "h1 a[href='#{user_path active_block.user}']", :text => active_block.user.display_name
    assert_select "h1 a[href='#{user_path active_block.creator}']", :text => active_block.creator.display_name
    assert UserBlock.find(active_block.id).needs_view

    # Login as the blocked user
    session_for(active_block.user)

    # Now viewing it should mark it as seen
    get user_block_path(:id => active_block)
    assert_response :success
    assert_not UserBlock.find(active_block.id).needs_view
  end

  ##
  # test edit/revoke link for active blocks
  def test_active_block_buttons
    creator_user = create(:moderator_user)
    other_moderator_user = create(:moderator_user)
    block = create(:user_block, :creator => creator_user)

    session_for(other_moderator_user)
    check_block_buttons block, :revoke => 1

    session_for(creator_user)
    check_block_buttons block, :edit => 1, :revoke => 1
  end

  ##
  # test the edit link for expired blocks
  def test_expired_block_buttons
    creator_user = create(:moderator_user)
    other_moderator_user = create(:moderator_user)
    block = create(:user_block, :expired, :creator => creator_user)

    session_for(other_moderator_user)
    check_block_buttons block

    session_for(creator_user)
    check_block_buttons block, :edit => 1
  end

  ##
  # test the edit link for revoked blocks
  def test_revoked_block_buttons
    creator_user = create(:moderator_user)
    revoker_user = create(:moderator_user)
    other_moderator_user = create(:moderator_user)
    block = create(:user_block, :revoked, :creator => creator_user, :revoker => revoker_user)

    session_for(other_moderator_user)
    check_block_buttons block

    session_for(creator_user)
    check_block_buttons block, :edit => 1

    session_for(revoker_user)
    check_block_buttons block, :edit => 1
  end

  ##
  # test the new action
  def test_new
    target_user = create(:user)

    # Check that the block creation page requires us to login
    get new_user_block_path(target_user)
    assert_redirected_to login_path(:referer => new_user_block_path(target_user))

    # Login as a normal user
    session_for(create(:user))

    # Check that normal users can't load the block creation page
    get new_user_block_path(target_user)
    assert_redirected_to :controller => "errors", :action => "forbidden"

    # Login as a moderator
    session_for(create(:moderator_user))

    # Check that the block creation page loads for moderators
    get new_user_block_path(target_user)
    assert_response :success
    assert_select "h1 a[href='#{user_path target_user}']", :text => target_user.display_name
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
    assert_redirected_to :controller => "errors", :action => "forbidden"

    # Login as a moderator
    session_for(create(:moderator_user))

    # Check that the block edit page loads for moderators
    get edit_user_block_path(:id => active_block)
    assert_response :success
    assert_select "h1 a[href='#{user_path active_block.user}']", :text => active_block.user.display_name
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
  # test the edit action when the remaining block duration doesn't match the available select options
  def test_edit_duration
    moderator_user = create(:moderator_user)

    freeze_time do
      active_block = create(:user_block, :creator => moderator_user, :ends_at => Time.now.utc + 96.hours)

      session_for(moderator_user)
      get edit_user_block_path(active_block)

      assert_select "form#edit_user_block_#{active_block.id}", :count => 1 do
        assert_select "select#user_block_period", :count => 1 do
          assert_select "option[value='96'][selected]", :count => 1
        end
      end

      travel 2.hours
      get edit_user_block_path(active_block)

      assert_select "form#edit_user_block_#{active_block.id}", :count => 1 do
        assert_select "select#user_block_period", :count => 1 do
          assert_select "option[value='96'][selected]", :count => 1
        end
      end
    end
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
    assert_redirected_to :controller => "errors", :action => "forbidden"

    # Login as a moderator
    session_for(moderator_user)

    # A bogus block period should result in an error
    assert_no_difference "UserBlock.count" do
      post user_blocks_path(:display_name => target_user.display_name,
                            :user_block_period => "99")
    end
    assert_redirected_to new_user_block_path(target_user)
    assert_equal "The blocking period must be one of the values selectable in the drop-down list.", flash[:error]

    # Check that creating a block works
    assert_difference "UserBlock.count", 1 do
      post user_blocks_path(:display_name => target_user.display_name,
                            :user_block_period => "12",
                            :user_block => { :needs_view => false, :reason => "Vandalism" })
    end
    b = UserBlock.last
    assert_redirected_to user_block_path(:id => b.id)
    assert_equal "Created a block on user #{target_user.display_name}.", flash[:notice]
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
  # test the duration of a created block
  def test_create_duration
    target_user = create(:user)
    moderator_user = create(:moderator_user)

    session_for(moderator_user)
    post user_blocks_path(:display_name => target_user.display_name,
                          :user_block_period => "336",
                          :user_block => { :needs_view => false, :reason => "Vandalism" })

    block = UserBlock.last
    assert_equal 1209600, block.ends_at - block.created_at
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
  # test the update action on expired blocks
  def test_update_expired
    creator_user = create(:moderator_user)
    other_moderator_user = create(:moderator_user)
    block = create(:user_block, :expired, :creator => creator_user, :reason => "Original Reason")

    session_for(other_moderator_user)
    put user_block_path(block,
                        :user_block_period => "0",
                        :user_block => { :needs_view => false, :reason => "Updated Reason" })
    assert_redirected_to edit_user_block_path(block)
    assert_equal "Only the moderator who created this block can edit it.", flash[:error]
    block.reload
    assert_not block.active?
    assert_equal "Original Reason", block.reason

    session_for(creator_user)
    check_block_updates(block)
  end

  ##
  # test the update action on revoked blocks
  def test_update_revoked
    creator_user = create(:moderator_user)
    revoker_user = create(:moderator_user)
    other_moderator_user = create(:moderator_user)
    block = create(:user_block, :revoked, :creator => creator_user, :revoker => revoker_user, :reason => "Original Reason")

    session_for(other_moderator_user)
    put user_block_path(block,
                        :user_block_period => "0",
                        :user_block => { :needs_view => false, :reason => "Updated Reason" })
    assert_redirected_to edit_user_block_path(block)
    assert_equal "Only the moderators who created or revoked this block can edit it.", flash[:error]
    block.reload
    assert_not_predicate block, :active?
    assert_equal "Original Reason", block.reason

    session_for(creator_user)
    check_block_updates(block)

    session_for(revoker_user)
    check_block_updates(block)
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
    assert_redirected_to :controller => "errors", :action => "forbidden"

    # Login as a moderator
    session_for(create(:moderator_user))

    # Check that the block revoke page loads for moderators
    get revoke_user_block_path(:id => active_block)
    assert_response :success
    assert_template "revoke"
    assert_select "h1 a[href='#{user_path active_block.user}']", :text => active_block.user.display_name
    assert_select "form", :count => 1 do
      assert_select "input#confirm[type='checkbox']", :count => 1
      assert_select "input[type='submit'][value='Revoke!']", :count => 1
    end

    # Check that revoking a block using GET should fail
    get revoke_user_block_path(:id => active_block, :confirm => true)
    assert_response :success
    assert_template "revoke"
    b = UserBlock.find(active_block.id)
    assert_operator b.ends_at - Time.now.utc, :>, 100

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
  # test the revoke all page
  def test_revoke_all_page
    blocked_user = create(:user)
    create(:user_block, :user => blocked_user)

    # Asking for the revoke all blocks page with a bogus user name should fail
    get user_blocks_on_path("non_existent_user")
    assert_response :not_found

    # Check that the revoke all blocks page requires us to login
    get revoke_all_user_blocks_path(blocked_user)
    assert_redirected_to login_path(:referer => revoke_all_user_blocks_path(blocked_user))

    # Login as a normal user
    session_for(create(:user))

    # Check that normal users can't load the revoke all blocks page
    get revoke_all_user_blocks_path(blocked_user)
    assert_redirected_to :controller => "errors", :action => "forbidden"

    # Login as a moderator
    session_for(create(:moderator_user))

    # Check that the revoke all blocks page loads for moderators
    get revoke_all_user_blocks_path(blocked_user)
    assert_response :success
    assert_select "h1 a[href='#{user_path blocked_user}']", :text => blocked_user.display_name
  end

  ##
  # test the revoke all action
  def test_revoke_all_action
    blocked_user = create(:user)
    active_block1 = create(:user_block, :user => blocked_user)
    active_block2 = create(:user_block, :user => blocked_user)
    expired_block1 = create(:user_block, :expired, :user => blocked_user)
    blocks = [active_block1, active_block2, expired_block1]
    moderator_user = create(:moderator_user)

    assert_predicate active_block1, :active?
    assert_predicate active_block2, :active?
    assert_not_predicate expired_block1, :active?

    # Login as a normal user
    session_for(create(:user))

    # Check that normal users can't load the block revoke page
    get revoke_all_user_blocks_path(:blocked_user)
    assert_redirected_to :controller => "errors", :action => "forbidden"

    # Login as a moderator
    session_for(moderator_user)

    # Check that revoking blocks using GET should fail
    get revoke_all_user_blocks_path(blocked_user, :confirm => true)
    assert_response :success
    assert_template "revoke_all"

    blocks.each(&:reload)
    assert_predicate active_block1, :active?
    assert_predicate active_block2, :active?
    assert_not_predicate expired_block1, :active?

    # Check that revoking blocks works using POST
    post revoke_all_user_blocks_path(blocked_user, :confirm => true)
    assert_redirected_to user_blocks_on_path(blocked_user)

    blocks.each(&:reload)
    assert_not_predicate active_block1, :active?
    assert_not_predicate active_block2, :active?
    assert_not_predicate expired_block1, :active?
    assert_equal moderator_user, active_block1.revoker
    assert_equal moderator_user, active_block2.revoker
    assert_not_equal moderator_user, expired_block1.revoker
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
    get user_blocks_on_path("non_existent_user")
    assert_response :not_found
    assert_template "users/no_such_user"
    assert_select "h1", "The user non_existent_user does not exist"

    # Check the list of blocks for a user that has never been blocked
    get user_blocks_on_path(normal_user)
    assert_response :success
    assert_select "table#block_list", false
    assert_select "p", "#{normal_user.display_name} has not been blocked yet."

    # Check the list of blocks for a user that is currently blocked
    get user_blocks_on_path(blocked_user)
    assert_response :success
    assert_select "h1 a[href='#{user_path blocked_user}']", :text => blocked_user.display_name
    assert_select "table#block_list tbody", :count => 1 do
      assert_select "tr", 2
      assert_select "a[href='#{user_block_path(active_block)}']", 1
      assert_select "a[href='#{user_block_path(revoked_block)}']", 1
    end

    # Check the list of blocks for a user that has previously been blocked
    get user_blocks_on_path(unblocked_user)
    assert_response :success
    assert_select "h1 a[href='#{user_path unblocked_user}']", :text => unblocked_user.display_name
    assert_select "table#block_list tbody", :count => 1 do
      assert_select "tr", 1
      assert_select "a[href='#{user_block_path(expired_block)}']", 1
    end
  end

  ##
  # test the blocks_on action with multiple pages
  def test_blocks_on_paged
    user = create(:user)
    user_blocks = create_list(:user_block, 50, :user => user).reverse
    next_path = user_blocks_on_path(user)

    get next_path
    assert_response :success
    check_user_blocks_table user_blocks[0...20]
    check_no_page_link "Newer Blocks"
    next_path = check_page_link "Older Blocks"

    get next_path
    assert_response :success
    check_user_blocks_table user_blocks[20...40]
    check_page_link "Newer Blocks"
    next_path = check_page_link "Older Blocks"

    get next_path
    assert_response :success
    check_user_blocks_table user_blocks[40...50]
    check_page_link "Newer Blocks"
    check_no_page_link "Older Blocks"
  end

  ##
  # test the blocks_on action with invalid pages
  def test_blocks_on_invalid_paged
    user = create(:user)

    %w[-1 0 fred].each do |id|
      get user_blocks_on_path(user, :before => id)
      assert_redirected_to :controller => :errors, :action => :bad_request

      get user_blocks_on_path(user, :after => id)
      assert_redirected_to :controller => :errors, :action => :bad_request
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
    get user_blocks_by_path("non_existent_user")
    assert_response :not_found
    assert_template "users/no_such_user"
    assert_select "h1", "The user non_existent_user does not exist"

    # Check the list of blocks given by one moderator
    get user_blocks_by_path(moderator_user)
    assert_response :success
    assert_select "h1 a[href='#{user_path moderator_user}']", :text => moderator_user.display_name
    assert_select "table#block_list tbody", :count => 1 do
      assert_select "tr", 1
      assert_select "a[href='#{user_block_path(active_block)}']", 1
    end

    # Check the list of blocks given by a different moderator
    get user_blocks_by_path(second_moderator_user)
    assert_response :success
    assert_select "h1 a[href='#{user_path second_moderator_user}']", :text => second_moderator_user.display_name
    assert_select "table#block_list tbody", :count => 1 do
      assert_select "tr", 2
      assert_select "a[href='#{user_block_path(expired_block)}']", 1
      assert_select "a[href='#{user_block_path(revoked_block)}']", 1
    end

    # Check the list of blocks (not) given by a normal user
    get user_blocks_by_path(normal_user)
    assert_response :success
    assert_select "table#block_list", false
    assert_select "p", "#{normal_user.display_name} has not made any blocks yet."
  end

  ##
  # test the blocks_by action with multiple pages
  def test_blocks_by_paged
    user = create(:moderator_user)
    user_blocks = create_list(:user_block, 50, :creator => user).reverse
    next_path = user_blocks_by_path(user)

    get next_path
    assert_response :success
    check_user_blocks_table user_blocks[0...20]
    check_no_page_link "Newer Blocks"
    next_path = check_page_link "Older Blocks"

    get next_path
    assert_response :success
    check_user_blocks_table user_blocks[20...40]
    check_page_link "Newer Blocks"
    next_path = check_page_link "Older Blocks"

    get next_path
    assert_response :success
    check_user_blocks_table user_blocks[40...50]
    check_page_link "Newer Blocks"
    check_no_page_link "Older Blocks"
  end

  ##
  # test the blocks_by action with invalid pages
  def test_blocks_by_invalid_paged
    user = create(:moderator_user)

    %w[-1 0 fred].each do |id|
      get user_blocks_by_path(user, :before => id)
      assert_redirected_to :controller => :errors, :action => :bad_request

      get user_blocks_by_path(user, :after => id)
      assert_redirected_to :controller => :errors, :action => :bad_request
    end
  end

  private

  def check_block_buttons(block, edit: 0, revoke: 0)
    [user_blocks_path, user_block_path(block)].each do |path|
      get path
      assert_response :success
      assert_select "a[href='#{edit_user_block_path block}']", :count => edit
      assert_select "a[href='#{revoke_user_block_path block}']", :count => revoke
    end
  end

  def check_block_updates(block)
    put user_block_path(block,
                        :user_block_period => "0",
                        :user_block => { :needs_view => false, :reason => "Updated Reason" })
    assert_redirected_to user_block_path(block)
    assert_equal "Block updated.", flash[:notice]
    block.reload
    assert_not_predicate block, :active?
    assert_equal "Updated Reason", block.reason

    put user_block_path(block,
                        :user_block_period => "0",
                        :user_block => { :needs_view => true, :reason => "Updated Reason 2" })
    assert_redirected_to user_block_path(block)
    assert_equal "Block updated.", flash[:notice]
    block.reload
    assert_predicate block, :active?
    assert_equal "Updated Reason 2", block.reason
  end

  def check_user_blocks_table(user_blocks)
    assert_dom "table#block_list tbody tr" do |rows|
      assert_equal user_blocks.count, rows.count, "unexpected number of rows in user blocks table"
      rows.zip(user_blocks).map do |row, user_block|
        assert_dom row, "a[href='#{user_block_path user_block}']", 1
      end
    end
  end

  def check_no_page_link(name)
    assert_select "a.page-link", { :text => /#{Regexp.quote(name)}/, :count => 0 }, "unexpected #{name} page link"
  end

  def check_page_link(name)
    assert_select "a.page-link", { :text => /#{Regexp.quote(name)}/ }, "missing #{name} page link" do |buttons|
      return buttons.first.attributes["href"].value
    end
  end
end
