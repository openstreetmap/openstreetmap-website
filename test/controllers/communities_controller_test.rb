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
  end

  def test_index_get
    c = create(:community)

    get communities_path

    assert_response :success
    assert_template "index"
    assert_match c.name, response.body
  end

  def test_index_with_specific_user
    c = create(:community)

    get user_communities_path(c.organizer.display_name)

    assert_response :success
    assert_template "index"
    assert_match c.name, response.body
  end

  def test_index_current_user
    c = create(:community)
    session_for(c.organizer)

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

  def test_edit_get_no_session
    c = create(:community)

    get edit_community_path(c)

    assert_response :redirect
    assert_redirected_to login_path(:referer => edit_community_path(c))
  end

  def test_update_as_non_organizer
    # Should this test be in abilities_test.rb?
    c = create(:community)
    other_user = create(:user)
    session_for(other_user)

    put community_path(c), :params => { :community => c.as_json }, :xhr => true

    assert_redirected_to :controller => :errors, :action => :forbidden
  end

  def test_update_put_success
    # TODO: When community_member is created switch to using that factory.
    c1 = create(:community) # original object
    c2 = build(:community) # new data
    session_for(c1.organizer)

    # Update c1 with the values from c2.
    put community_url(c1), :params => { :community => c2.as_json }, :xhr => true

    assert_redirected_to community_path(c1)
    assert_equal I18n.t("communities.update.success"), flash[:notice]
    c1.reload
    # Assign the id of c1 to c2, so we can do an equality test easily.
    c2.id = c1.id
    assert_equal(c2, c1)
  end

  def test_update_put_failure
    # TODO: When community_member is created switch to using that factory.
    c1 = create(:community) # original object
    session_for(c1.organizer)
    form = c1.attributes.except("id", "created_at", "updated_at", "slug")
    # Force an update failure based on validation.
    form["latitude"] = 100.0

    assert_difference "Community.count", 0 do
      put community_url(c1), :params => { :community => form.as_json }, :xhr => true
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

  def test_create_when_save_works
    c_orig = create(:community)
    session_for(c_orig.organizer)

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
end
