require "test_helper"
require_relative "user_blocks/table_test_helper"

class UserBlocksControllerTest < ActionDispatch::IntegrationTest
  include UserBlocks::TableTestHelper

  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/user_blocks/new/username", :method => :get },
      { :controller => "user_blocks", :action => "new", :display_name => "username" }
    )

    assert_routing(
      { :path => "/user_blocks", :method => :get },
      { :controller => "user_blocks", :action => "index" }
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
    get user_block_path(99999)
    assert_response :not_found
    assert_template "not_found"
    assert_select "p", "Sorry, the user block with ID 99999 could not be found."

    # Viewing an expired block should work
    get user_block_path(expired_block)
    assert_response :success
    assert_select "h1 a[href='#{user_path expired_block.user}']", :text => expired_block.user.display_name
    assert_select "h1 a[href='#{user_path expired_block.creator}']", :text => expired_block.creator.display_name

    # Viewing a revoked block should work
    get user_block_path(revoked_block)
    assert_response :success
    assert_select "h1 a[href='#{user_path revoked_block.user}']", :text => revoked_block.user.display_name
    assert_select "h1 a[href='#{user_path revoked_block.creator}']", :text => revoked_block.creator.display_name
    assert_select "a[href='#{user_path revoked_block.revoker}']", :text => revoked_block.revoker.display_name

    # Viewing an active block should work, but shouldn't mark it as seen
    get user_block_path(active_block)
    assert_response :success
    assert_select "h1 a[href='#{user_path active_block.user}']", :text => active_block.user.display_name
    assert_select "h1 a[href='#{user_path active_block.creator}']", :text => active_block.creator.display_name
    assert UserBlock.find(active_block.id).needs_view
  end

  ##
  # test clearing needs_view by showing a zero-hour block to the blocked user
  def test_show_sets_deactivates_at_for_zero_hour_block
    user = create(:user)
    session_for(user)

    freeze_time do
      block = create(:user_block, :needs_view, :zero_hour, :user => user)
      assert block.needs_view
      assert_nil block.deactivates_at

      travel 1.hour

      get user_block_path(block)
      assert_response :success
      block.reload
      assert_not block.needs_view
      assert_equal Time.now.utc, block.deactivates_at

      travel 1.hour

      get user_block_path(block)
      assert_response :success
      block.reload
      assert_not block.needs_view
      assert_equal Time.now.utc - 1.hour, block.deactivates_at
    end
  end

  ##
  # test clearing needs_view by showing a timed block to the blocked user
  def test_show_sets_deactivates_at_for_timed_block
    user = create(:user)
    session_for(user)

    freeze_time do
      block = create(:user_block, :needs_view, :created_at => Time.now.utc, :ends_at => Time.now.utc + 24.hours, :user => user)
      assert block.needs_view
      assert_nil block.deactivates_at

      travel 1.hour

      get user_block_path(block)
      assert_response :success
      block.reload
      assert_not block.needs_view
      assert_equal Time.now.utc + 23.hours, block.deactivates_at

      travel 1.hour

      get user_block_path(block)
      assert_response :success
      block.reload
      assert_not block.needs_view
      assert_equal Time.now.utc + 22.hours, block.deactivates_at

      travel 24.hours

      get user_block_path(block)
      assert_response :success
      block.reload
      assert_not block.needs_view
      assert_equal Time.now.utc - 2.hours, block.deactivates_at
    end
  end

  ##
  # test edit/revoke link for active blocks
  def test_active_block_buttons
    creator_user = create(:moderator_user)
    other_moderator_user = create(:moderator_user)
    block = create(:user_block, :creator => creator_user)

    session_for(other_moderator_user)
    check_block_buttons block, :edit => 1

    session_for(creator_user)
    check_block_buttons block, :edit => 1
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
    get new_user_block_path("non_existent_user")
    assert_response :not_found
    assert_template "users/no_such_user"
    assert_select "h1", "The user non_existent_user does not exist"
  end

  ##
  # test the edit action
  def test_edit
    creator_user = create(:moderator_user)
    other_moderator_user = create(:moderator_user)
    active_block = create(:user_block, :creator => creator_user)

    # Check that the block edit page requires us to login
    get edit_user_block_path(active_block)
    assert_redirected_to login_path(:referer => edit_user_block_path(active_block))

    # Login as a normal user
    session_for(create(:user))

    # Check that normal users can't load the block edit page
    get edit_user_block_path(active_block)
    assert_redirected_to :controller => "errors", :action => "forbidden"

    # Login as a moderator
    session_for(other_moderator_user)

    # Check that the block edit page loads for moderators
    get edit_user_block_path(active_block)
    assert_response :success
    assert_select "h1 a[href='#{user_path active_block.user}']", :text => active_block.user.display_name
    assert_select "form#edit_user_block_#{active_block.id}", :count => 1 do
      assert_select "textarea#user_block_reason", :count => 1
      assert_select "select#user_block_period", :count => 0
      assert_select "input#user_block_needs_view[type='checkbox']", :count => 0
      assert_select "input[type='submit'][value='Update block']", :count => 0
      assert_select "input#user_block_period[type='hidden']", :count => 1
      assert_select "input#user_block_needs_view[type='hidden']", :count => 1
      assert_select "input[type='submit'][value='Revoke block']", :count => 1
    end

    # Login as the block creator
    session_for(creator_user)

    # Check that the block edit page loads for the creator
    get edit_user_block_path(active_block)
    assert_response :success
    assert_select "h1 a[href='#{user_path active_block.user}']", :text => active_block.user.display_name
    assert_select "form#edit_user_block_#{active_block.id}", :count => 1 do
      assert_select "textarea#user_block_reason", :count => 1
      assert_select "select#user_block_period", :count => 1
      assert_select "input#user_block_needs_view[type='checkbox']", :count => 1
      assert_select "input[type='submit'][value='Update block']", :count => 1
      assert_select "input#user_block_period[type='hidden']", :count => 0
      assert_select "input#user_block_needs_view[type='hidden']", :count => 0
      assert_select "input[type='submit'][value='Revoke block']", :count => 0
    end

    # We should get an error if the user doesn't exist
    get edit_user_block_path(99999)
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
    assert_redirected_to user_block_path(b)
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
    active_block = create(:user_block, :creator => moderator_user)

    # Not logged in yet, so updating a block should fail
    put user_block_path(active_block)
    assert_response :forbidden

    # Login as a normal user
    session_for(create(:user))

    # Check that normal users can't update blocks
    put user_block_path(active_block)
    assert_redirected_to :controller => "errors", :action => "forbidden"

    # Login as the moderator
    session_for(moderator_user)

    # A bogus block period should result in an error
    assert_no_difference "UserBlock.count" do
      put user_block_path(active_block, :user_block_period => "99")
    end
    assert_redirected_to edit_user_block_path(active_block)
    assert_equal "The blocking period must be one of the values selectable in the drop-down list.", flash[:error]

    # Check that updating a block works
    assert_no_difference "UserBlock.count" do
      put user_block_path(active_block,
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
    put user_block_path(99999)
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
    check_inactive_block_updates(block)
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
    check_inactive_block_updates(block)

    session_for(revoker_user)
    check_inactive_block_updates(block)
  end

  ##
  # test the update action revoking the block
  def test_revoke_using_update_by_creator
    moderator_user = create(:moderator_user)
    block = create(:user_block, :creator => moderator_user)

    session_for(moderator_user)
    put user_block_path(block,
                        :user_block_period => "24",
                        :user_block => { :needs_view => false, :reason => "Updated Reason" })
    assert_redirected_to user_block_path(block)
    assert_equal "Block updated.", flash[:notice]
    block.reload
    assert_predicate block, :active?
    assert_nil block.revoker

    put user_block_path(block,
                        :user_block_period => "0",
                        :user_block => { :needs_view => false, :reason => "Updated Reason" })
    assert_redirected_to user_block_path(block)
    assert_equal "Block updated.", flash[:notice]
    block.reload
    assert_not_predicate block, :active?
    assert_equal moderator_user, block.revoker
  end

  def test_revoke_using_update_by_other_moderator
    creator_user = create(:moderator_user)
    other_moderator_user = create(:moderator_user)
    block = create(:user_block, :creator => creator_user)

    session_for(other_moderator_user)
    put user_block_path(block,
                        :user_block_period => "24",
                        :user_block => { :needs_view => false, :reason => "Updated Reason" })
    assert_response :success
    assert_equal "Only the moderator who created this block can edit it without revoking.", flash[:error]
    block.reload
    assert_predicate block, :active?
    assert_nil block.revoker

    put user_block_path(block,
                        :user_block_period => "0",
                        :user_block => { :needs_view => false, :reason => "Updated Reason" })
    assert_redirected_to user_block_path(block)
    assert_equal "Block updated.", flash[:notice]
    block.reload
    assert_not_predicate block, :active?
    assert_equal other_moderator_user, block.revoker
  end

  ##
  # test changes to end/deactivation dates
  def test_dates_when_viewed_before_end
    blocked_user = create(:user)
    moderator_user = create(:moderator_user)

    freeze_time do
      session_for(moderator_user)
      assert_difference "UserBlock.count", 1 do
        post user_blocks_path(:display_name => blocked_user.display_name,
                              :user_block_period => "48",
                              :user_block => { :needs_view => true, :reason => "Testing deactivates_at" })
      end
      block = UserBlock.last
      assert_equal Time.now.utc + 48.hours, block.ends_at
      assert_nil block.deactivates_at

      travel 24.hours
      session_for(blocked_user)
      get user_block_path(block)
      block.reload
      assert_equal Time.now.utc + 24.hours, block.ends_at
      assert_equal Time.now.utc + 24.hours, block.deactivates_at
    end
  end

  def test_dates_when_viewed_after_end
    blocked_user = create(:user)
    moderator_user = create(:moderator_user)

    freeze_time do
      session_for(moderator_user)
      assert_difference "UserBlock.count", 1 do
        post user_blocks_path(:display_name => blocked_user.display_name,
                              :user_block_period => "24",
                              :user_block => { :needs_view => true, :reason => "Testing deactivates_at" })
      end
      block = UserBlock.last
      assert_equal Time.now.utc + 24.hours, block.ends_at
      assert_nil block.deactivates_at

      travel 48.hours
      session_for(blocked_user)
      get user_block_path(block)
      block.reload
      assert_equal Time.now.utc - 24.hours, block.ends_at
      assert_equal Time.now.utc, block.deactivates_at
    end
  end

  def test_dates_when_edited_before_end
    blocked_user = create(:user)
    moderator_user = create(:moderator_user)

    freeze_time do
      session_for(moderator_user)
      assert_difference "UserBlock.count", 1 do
        post user_blocks_path(:display_name => blocked_user.display_name,
                              :user_block_period => "48",
                              :user_block => { :needs_view => false, :reason => "Testing deactivates_at" })
      end
      block = UserBlock.last
      assert_equal Time.now.utc + 48.hours, block.ends_at
      assert_equal Time.now.utc + 48.hours, block.deactivates_at

      travel 24.hours
      put user_block_path(block,
                          :user_block_period => "48",
                          :user_block => { :needs_view => false, :reason => "Testing deactivates_at updated" })
      block.reload
      assert_equal Time.now.utc + 48.hours, block.ends_at
      assert_equal Time.now.utc + 48.hours, block.deactivates_at
    end
  end

  def test_dates_when_edited_after_end
    blocked_user = create(:user)
    moderator_user = create(:moderator_user)

    freeze_time do
      session_for(moderator_user)
      assert_difference "UserBlock.count", 1 do
        post user_blocks_path(:display_name => blocked_user.display_name,
                              :user_block_period => "24",
                              :user_block => { :needs_view => false, :reason => "Testing deactivates_at" })
      end
      block = UserBlock.last
      assert_equal Time.now.utc + 24.hours, block.ends_at
      assert_equal Time.now.utc + 24.hours, block.deactivates_at

      travel 48.hours
      put user_block_path(block,
                          :user_block_period => "0",
                          :user_block => { :needs_view => false, :reason => "Testing deactivates_at updated" })
      block.reload
      assert_equal Time.now.utc - 24.hours, block.ends_at
      assert_equal Time.now.utc - 24.hours, block.deactivates_at
    end
  end

  ##
  # test updates on legacy records without correctly initialized deactivates_at
  def test_update_legacy_deactivates_at
    blocked_user = create(:user)
    moderator_user = create(:moderator_user)

    freeze_time do
      block = UserBlock.new :user => blocked_user,
                            :creator => moderator_user,
                            :reason => "because",
                            :ends_at => Time.now.utc + 24.hours,
                            :needs_view => false

      assert_difference "UserBlock.count", 1 do
        block.save :validate => false
      end

      travel 48.hours
      session_for(moderator_user)
      put user_block_path(block,
                          :user_block_period => "0",
                          :user_block => { :needs_view => false, :reason => "Testing legacy block update" })
      block.reload
      assert_equal Time.now.utc - 24.hours, block.ends_at
      assert_equal Time.now.utc - 24.hours, block.deactivates_at
    end
  end

  private

  def check_block_buttons(block, edit: 0)
    [user_blocks_path, user_block_path(block)].each do |path|
      get path
      assert_response :success
      assert_select "a[href='#{edit_user_block_path block}']", :count => edit
    end
  end

  def check_inactive_block_updates(block)
    original_ends_at = block.ends_at

    put user_block_path(block,
                        :user_block_period => "0",
                        :user_block => { :needs_view => false, :reason => "Updated Reason" })
    assert_redirected_to user_block_path(block)
    assert_equal "Block updated.", flash[:notice]
    block.reload
    assert_not_predicate block, :active?
    assert_equal "Updated Reason", block.reason
    assert_equal original_ends_at, block.ends_at

    put user_block_path(block,
                        :user_block_period => "0",
                        :user_block => { :needs_view => true, :reason => "Updated Reason Needs View" })
    assert_response :success
    assert_equal "This block is inactive and cannot be reactivated.", flash[:error]
    block.reload
    assert_not_predicate block, :active?
    assert_equal "Updated Reason", block.reason
    assert_equal original_ends_at, block.ends_at

    put user_block_path(block,
                        :user_block_period => "1",
                        :user_block => { :needs_view => false, :reason => "Updated Reason Duration Extended" })
    assert_response :success
    assert_equal "This block is inactive and cannot be reactivated.", flash[:error]
    block.reload
    assert_not_predicate block, :active?
    assert_equal "Updated Reason", block.reason
    assert_equal original_ends_at, block.ends_at

    put user_block_path(block,
                        :user_block_period => "0",
                        :user_block => { :needs_view => false, :reason => "Updated Reason Again" })
    assert_redirected_to user_block_path(block)
    assert_equal "Block updated.", flash[:notice]
    block.reload
    assert_not_predicate block, :active?
    assert_equal "Updated Reason Again", block.reason
    assert_equal original_ends_at, block.ends_at
  end
end
