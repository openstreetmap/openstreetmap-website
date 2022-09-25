require "test_helper"

class CommunitiesControllerTest < ActionDispatch::IntegrationTest
  ##
  # test all routes which lead to this controller
  # Following guidance from Ruby on Rails Guide
  # https://guides.rubyonrails.org/testing.html#functional-tests-for-your-controllers
  #
  def test_routes
    assert_routing(
      { :path => "/communities", :method => :get },
      { :controller => "communities", :action => "index" }
    )
    assert_routing(
      { :path => "/communities/1", :method => :get },
      { :controller => "communities", :action => "show", :id => "1" }
    )
    assert_routing(
      { :path => "/communities/mdc", :method => :get },
      { :controller => "communities", :action => "show", :id => "mdc" }
    )
    assert_routing(
      { :path => "/communities/mdc/edit", :method => :get },
      { :controller => "communities", :action => "edit", :id => "mdc" }
    )
    assert_routing(
      { :path => "/communities/mdc", :method => :put },
      { :controller => "communities", :action => "update", :id => "mdc" }
    )
    assert_routing(
      { :path => "/communities/new", :method => :get },
      { :controller => "communities", :action => "new" }
    )
    assert_routing(
      { :path => "/communities", :method => :post },
      { :controller => "communities", :action => "create" }
    )
    assert_routing(
      { :path => "/communities/mdc/community_members", :method => :get },
      { :controller => "community_members", :action => "index", :community_id => "mdc" }
    )
  end

  def test_index_get
    c = create(:community)
    create(:community_member, :community => c)
    create(:community_member, :community => c)
    create(:community_member, :community => c)

    get communities_path

    assert_response :success
    assert_template "index"
    assert_match c.name, response.body
  end

  def test_index_get_not_enough_members
    c = create(:community)
    create(:community_member, :community => c)
    create(:community_member, :community => c)

    get communities_path

    assert_response :success
    assert_template "index"
    assert_no_match c.name, response.body
  end

  def test_index_with_specific_user
    c = create(:community)

    get user_communities_path(c.leader.display_name)

    assert_response :success
    assert_template "index"
    assert_match c.name, response.body
  end

  def test_index_current_user
    c = create(:community)
    session_for(c.leader)

    get communities_path

    assert_response :success
    assert_template "index"
    assert_match c.name, response.body
  end

  def test_index_user_does_not_exist
    create(:community)

    get "/user/user_dne/communities"

    assert_response :not_found
    assert_no_missing_translations
  end

  def test_show_get
    c = create(:community)
    ch = create(:changeset)
    # Make sure this changeset is in the community area.
    min_lat = (c.min_lat * GeoRecord::SCALE).to_i
    max_lat = (c.max_lat * GeoRecord::SCALE).to_i
    min_lon = (c.min_lon * GeoRecord::SCALE).to_i
    max_lon = (c.max_lon * GeoRecord::SCALE).to_i
    ch.min_lat = rand(min_lat...max_lat)
    ch.max_lat = rand(min_lat...max_lat)
    ch.min_lon = rand(min_lon...max_lon)
    ch.max_lon = rand(min_lon...max_lon)
    ch.save!
    create(:changeset_tag, :changeset => ch, :k => "comment", :v => "test comment")

    get community_path(c)

    assert_response :success
    assert_template("show")
    assert_match c.name, response.body
    assert_match c.description, response.body
    assert_match "test comment", response.body
  end

  def test_show_does_not_exist
    get community_path("foo")

    assert_response :not_found
    assert_template("no_such_community")
  end

  def test_edit_get_no_session
    c = create(:community)

    get edit_community_path(c)

    assert_response :redirect
    assert_redirected_to login_path(:referer => edit_community_path(c))
  end

  def test_edit_get_is_not_member_is_not_organizer
    c = create(:community)
    user = create(:user)
    session_for(user)

    get edit_community_path(c)

    assert_redirected_to :controller => :errors, :action => :forbidden
  end

  def test_edit_get_is_member_not_organizer
    cm = create(:community_member)
    session_for(cm.user)

    get edit_community_path(cm.community)

    assert_redirected_to :controller => :errors, :action => :forbidden
  end

  def test_edit_get_is_organizer
    cm = create(:community_member, :organizer)
    # We need to reload the object from PG because the floats in Ruby translate
    # to double precision in PG and will actually loose 1 digit of precision.  PG
    # says 15, but it doesn't get that.  Reload so values below are correct.
    cm.reload
    session_for(cm.user)

    get edit_community_path(cm.community)

    assert_response :success
    assert_select "div#content", :count => 1 do
      assert_select "form[action='/communities/#{cm.community.slug}'][method=post]", :count => 1 do
        assert_select "input#community_location[name='community[location]'][value='#{cm.community.location}']", :count => 1
        assert_select "input#community_latitude[name='community[latitude]'][value='#{cm.community.latitude}']", :count => 1
        assert_select "input#community_longitude[name='community[longitude]'][value='#{cm.community.longitude}']", :count => 1
        assert_select "input#community_min_lat[name='community[min_lat]'][value='#{cm.community.min_lat}']", :count => 1
        assert_select "input#community_max_lat[name='community[max_lat]'][value='#{cm.community.max_lat}']", :count => 1
        assert_select "input#community_min_lon[name='community[min_lon]'][value='#{cm.community.min_lon}']", :count => 1
        assert_select "input#community_max_lon[name='community[max_lon]'][value='#{cm.community.max_lon}']", :count => 1
        assert_select "textarea#community_description[name='community[description]']", :text => cm.community.description, :count => 1
        assert_select "input", :count => 10
      end
    end
  end

  def test_update_as_non_organizer
    # Should this test be in abilities_test.rb?
    c = create(:community)
    other_user = create(:user)
    session_for(other_user)

    put community_path(c), :params => { :community => c.as_json }, :xhr => true

    assert_redirected_to :controller => :errors, :action => :forbidden
  end

  def test_update_success
    # TODO: When community_member is created switch to using that factory.
    c1 = create_community_with_organizer # original object
    c2 = build(:community) # new data
    session_for(c1.leader)

    # Update c1 with the values from c2.
    put community_url(c1), :params => { :community => c2.as_json }, :xhr => true

    assert_redirected_to community_path(c1)
    assert_equal I18n.t("communities.update.success"), flash[:notice]
    c1.reload
    # Assign the id of c1 to c2, so we can do an equality test easily.
    c2.id = c1.id
    assert_equal(c2, c1)
  end

  # TODO: Really we should test abilities separately
  # https://github.com/CanCanCommunity/cancancan/wiki/Testing-Abilities
  def test_update_success_as_non_organizer
    cm = create(:community_member)
    # cm = create(:community_member, :user => cm.user)
    session_for(cm.user)
    c1 = cm.community # original object
    c2 = build(:community) # new data

    # Update c1 with the values from c2.
    put community_url(c1), :params => { :community => c2.as_json }, :xhr => true

    assert_redirected_to :controller => :errors, :action => :forbidden
  end

  def test_update_failure
    c = create_community_with_organizer # original object
    session_for(c.leader)
    form = c.attributes.except("id", "created_at", "updated_at", "slug")
    # Force an update failure based on validation.
    form["latitude"] = 100.0

    assert_difference "Community.count", 0 do
      put community_url(c), :params => { :community => form.as_json }, :xhr => true
    end

    assert_equal I18n.t("communities.update.failure"), flash[:alert]
  end

  def test_new_no_login
    # Make sure that you are redirected to the login page when you
    # are not logged in
    get new_community_path

    assert_response :redirect
    assert_redirected_to login_path(:referer => new_community_path)
  end

  def test_new_form
    # Now try again when logged in
    session_for(create(:user))

    get new_community_path
    assert_response :success
    # assert_select "title", :text => /New Community/, :count => 1
    assert_select "div.content-heading", :count => 1 do
      assert_select "h1", :text => /Community/, :count => 1
    end
    assert_select "div#content", :count => 1 do
      assert_select "form[action='/communities'][method=post]", :count => 1 do
        assert_select "input#community_location[name='community[location]']", :count => 1
        assert_select "input#community_latitude[name='community[latitude]']", :count => 1
        assert_select "input#community_longitude[name='community[longitude]']", :count => 1
        assert_select "input#community_min_lat[name='community[min_lat]']", :count => 1
        assert_select "input#community_max_lat[name='community[max_lat]']", :count => 1
        assert_select "input#community_min_lon[name='community[min_lon]']", :count => 1
        assert_select "input#community_max_lon[name='community[max_lon]']", :count => 1
        assert_select "textarea#community_description[name='community[description]']", :count => 1
        assert_select "input", :count => 9
      end
    end
  end

  # also tests add_first_organizer
  def test_create_when_save_works
    c_orig = create(:community)
    session_for(c_orig.leader)

    c_new_slug = nil
    assert_difference "Community.count", 1 do
      post communities_url, :params => { :community => c_orig.as_json }, :xhr => true
      c_new_slug = @response.headers["Location"].split("/")[-1]
    end

    assert_equal I18n.t("communities.create.success"), flash[:notice]
    c_new = Community.find_by(:slug => c_new_slug)
    # Assign the id c_new to c_orig, so we can do an equality test easily.
    c_orig.id = c_new.id
    assert_equal(c_orig, c_new)
  end

  def test_create_when_save_fails
    session_for(create(:user))
    c = create(:community)
    form = c.attributes.except("id", "created_at", "updated_at", "slug")
    form["latitude"] = 100.0

    assert_difference "Community.count", 0 do
      post communities_path, :params => { :community => form.as_json }, :xhr => true
      assert_response :success
      assert_template "new"
    end
  end

  def test_create_with_coords_out_of_range
    u = create(:user)
    session_for(u)
    c_orig = create(:community)
    c_orig.longitude = -200

    c_new_slug = nil
    assert_difference "Community.count", 1 do
      post communities_url, :params => { :community => c_orig.as_json }, :xhr => true
      c_new_slug = @response.headers["Location"].split("/")[-1]
    end

    assert_equal I18n.t("communities.create.success"), flash[:notice]
    c_new = Community.find_by(:slug => c_new_slug)
    # Assign the id c_new to c_orig, so we can do an equality test easily.
    c_orig.id = c_new.id
    assert_equal 160, c_new.longitude
  end

  def test_step_up_non_member
    u = create(:user)
    session_for(u)
    c = create(:community)

    post step_up_url(c.id)
    follow_redirect!

    assert_equal I18n.t("communities.step_up.only_members_can_step_up"), flash[:notice]
  end

  def test_step_up_member
    cm = create(:community_member)
    session_for(cm.user)

    post step_up_url(cm.community.id)
    follow_redirect!

    assert_equal I18n.t("communities.step_up.you_have_stepped_up"), flash[:notice]
  end

  def test_step_up_already_has_organizer
    cm = create(:community_member, :organizer)
    session_for(cm.user)

    post step_up_url(cm.community.id)
    follow_redirect!

    assert_equal I18n.t("communities.step_up.already_has_organizer"), flash[:notice]
  end

  def test_show_members_get
    cm = create(:community_member)

    get community_community_members_path(cm.community.id)

    assert_response :success
    assert_match cm.user.display_name, response.body
  end
end
