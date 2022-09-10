require "test_helper"

class MicrocosmsControllerTest < ActionDispatch::IntegrationTest
  ##
  # test all routes which lead to this controller
  # Following guidance from Ruby on Rails Guide
  # https://guides.rubyonrails.org/testing.html#functional-tests-for-your-controllers
  #
  def test_routes
    assert_routing(
      { :path => "/microcosms", :method => :get },
      { :controller => "microcosms", :action => "index" }
    )
    assert_routing(
      { :path => "/microcosms/1", :method => :get },
      { :controller => "microcosms", :action => "show", :id => "1" }
    )
    assert_routing(
      { :path => "/microcosms/mdc", :method => :get },
      { :controller => "microcosms", :action => "show", :id => "mdc" }
    )
    assert_routing(
      { :path => "/microcosms/mdc/edit", :method => :get },
      { :controller => "microcosms", :action => "edit", :id => "mdc" }
    )
    assert_routing(
      { :path => "/microcosms/mdc", :method => :put },
      { :controller => "microcosms", :action => "update", :id => "mdc" }
    )
    assert_routing(
      { :path => "/microcosms/new", :method => :get },
      { :controller => "microcosms", :action => "new" }
    )
    assert_routing(
      { :path => "/microcosms", :method => :post },
      { :controller => "microcosms", :action => "create" }
    )
  end

  def test_index_get
    # arrange
    m = create(:microcosm)
    # act
    get microcosms_path
    # assert
    assert_response :success
    assert_template "index"
    assert_match m.name, response.body
  end

  def test_index_with_specific_user
    # arrange
    m = create(:microcosm)
    # act
    get user_microcosms_path(m.organizer.display_name)
    # assert
    assert_response :success
    assert_template "index"
    assert_match m.name, response.body
  end

  def test_index_current_user
    # arrange
    m = create(:microcosm)
    session_for(m.organizer)
    # act
    get microcosms_path
    # assert
    assert_response :success
    assert_template "index"
    assert_match m.name, response.body
  end

  def test_index_user_does_not_exist
    # arrange
    create(:microcosm)
    # act
    get "/user/user_dne/microcosms"
    # assert
    assert_response :not_found
    assert_no_missing_translations
  end

  def test_show_get
    # arrange
    m = create(:microcosm)
    ch = create(:changeset)
    # Make sure this changeset is in the microcosm area.
    min_lat = (m.min_lat * GeoRecord::SCALE).to_i
    max_lat = (m.max_lat * GeoRecord::SCALE).to_i
    min_lon = (m.min_lon * GeoRecord::SCALE).to_i
    max_lon = (m.max_lon * GeoRecord::SCALE).to_i
    ch.min_lat = rand(min_lat...max_lat)
    ch.max_lat = rand(min_lat...max_lat)
    ch.min_lon = rand(min_lon...max_lon)
    ch.max_lon = rand(min_lon...max_lon)
    ch.save!
    create(:changeset_tag, :changeset => ch, :k => "comment", :v => "test comment")
    # act
    get microcosm_path(m)
    # assert
    assert_response :success
    assert_template("show")
    assert_match m.name, response.body
    assert_match m.description, response.body
    assert_match "test comment", response.body
  end

  def test_edit_get_no_session
    # arrange
    m = create(:microcosm)
    # act
    get edit_microcosm_path(m)
    # assert
    assert_response :redirect
    assert_redirected_to login_path(:referer => edit_microcosm_path(m))
  end

  def test_update_as_non_organizer
    # Should this test be in abilities_test.rb?
    # arrange
    m = create(:microcosm)
    other_user = create(:user)
    session_for(other_user)
    # act
    put microcosm_path(m), :params => { :microcosm => m.as_json }, :xhr => true
    # assert
    assert_redirected_to :controller => :errors, :action => :forbidden
  end

  def test_update_put_success
    # TODO: When microcosm_member is created switch to using that factory.
    # arrange
    m1 = create(:microcosm) # original object
    m2 = build(:microcosm) # new data
    session_for(m1.organizer)

    # act
    # Update m1 with the values from m2.
    put microcosm_url(m1), :params => { :microcosm => m2.as_json }, :xhr => true

    # assert
    assert_redirected_to microcosm_path(m1)
    assert_equal I18n.t("microcosms.update.success"), flash[:notice]
    m1.reload
    # Assign the id of m1 to m2, so we can do an equality test easily.
    m2.id = m1.id
    assert_equal(m2, m1)
  end

  def test_update_put_failure
    # TODO: When microcosm_member is created switch to using that factory.
    # arrange
    m1 = create(:microcosm) # original object
    session_for(m1.organizer)
    form = m1.attributes.except("id", "created_at", "updated_at", "slug")
    # Force an update failure based on validation.
    form["latitude"] = 100.0

    # act
    assert_difference "Microcosm.count", 0 do
      put microcosm_url(m1), :params => { :microcosm => form.as_json }, :xhr => true
    end

    # assert
    assert_equal I18n.t("microcosms.update.failure"), flash[:alert]
  end

  def test_new_no_login
    # Make sure that you are redirected to the login page when you
    # are not logged in
    # act
    get new_microcosm_path
    # assert
    assert_response :redirect
    assert_redirected_to login_path(:referer => new_microcosm_path)
  end

  def test_new_form
    # Now try again when logged in
    # arrange
    session_for(create(:user))
    # act
    get new_microcosm_path
    # assert
    assert_response :success
    # assert_select "title", :text => /New Microcosm/, :count => 1
    assert_select "div.content-heading", :count => 1 do
      assert_select "h1", :text => /Microcosm/, :count => 1
    end
    assert_select "div#content", :count => 1 do
      assert_select "form[action='/microcosms'][method=post]", :count => 1 do
        assert_select "input#microcosm_location[name='microcosm[location]']", :count => 1
        assert_select "input#microcosm_latitude[name='microcosm[latitude]']", :count => 1
        assert_select "input#microcosm_longitude[name='microcosm[longitude]']", :count => 1
        assert_select "input#microcosm_min_lat[name='microcosm[min_lat]']", :count => 1
        assert_select "input#microcosm_max_lat[name='microcosm[max_lat]']", :count => 1
        assert_select "input#microcosm_min_lon[name='microcosm[min_lon]']", :count => 1
        assert_select "input#microcosm_max_lon[name='microcosm[max_lon]']", :count => 1
        assert_select "textarea#microcosm_description[name='microcosm[description]']", :count => 1
        assert_select "input", :count => 10
      end
    end
  end

  def test_create_when_save_works
    # arrange
    m_orig = create(:microcosm)
    session_for(m_orig.organizer)

    # act
    m_new_slug = nil
    assert_difference "Microcosm.count", 1 do
      post microcosms_url, :params => { :microcosm => m_orig.as_json }, :xhr => true
      m_new_slug = @response.headers["Location"].split("/")[-1]
    end

    # assert
    assert_equal I18n.t("microcosms.create.success"), flash[:notice]
    m_new = Microcosm.find_by(:slug => m_new_slug)
    # Assign the id m_new to m_orig, so we can do an equality test easily.
    m_orig.id = m_new.id
    assert_equal(m_orig, m_new)
  end

  def test_create_when_save_fails
    # arrange
    session_for(create(:user))
    m = create(:microcosm)
    form = m.attributes.except("id", "created_at", "updated_at", "slug")
    form["latitude"] = 100.0

    # act and assert
    assert_difference "Microcosm.count", 0 do
      post microcosms_path, :params => { :microcosm => form.as_json }, :xhr => true
      assert_response :success
      assert_template "new"
    end
  end

  def test_create_with_coords_out_of_range
    # arrange
    u = create(:user)
    session_for(u)
    m_orig = create(:microcosm)
    m_orig.longitude = -200

    # act
    m_new_slug = nil
    assert_difference "Microcosm.count", 1 do
      post microcosms_url, :params => { :microcosm => m_orig.as_json }, :xhr => true
      m_new_slug = @response.headers["Location"].split("/")[-1]
    end

    # assert
    assert_equal I18n.t("microcosms.create.success"), flash[:notice]
    m_new = Microcosm.find_by(:slug => m_new_slug)
    # Assign the id m_new to m_orig, so we can do an equality test easily.
    m_orig.id = m_new.id
    assert_equal 160, m_new.longitude
  end
end
