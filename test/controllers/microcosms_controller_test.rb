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
      { :path => "/microcosms/mdc/members", :method => :get },
      { :controller => "microcosms", :action => "show_members", :id => "mdc" }
    )
    assert_routing(
      { :path => "/microcosms/mdc/events", :method => :get },
      { :controller => "microcosms", :action => "show_events", :id => "mdc" }
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

  def check_page_basics
    assert_response :success
    assert_no_missing_translations
  end

  def test_index_get
    # arrange
    m = create(:microcosm)
    # act
    get microcosms_path
    # assert
    check_page_basics
    assert_template "index"
    assert_match m.name, response.body
  end

  def test_show_get
    # arrange
    m = create(:microcosm)
    # act
    get microcosm_path(m)
    # assert
    check_page_basics
    # assert_template("show")
    assert_match m.name, response.body
    assert_match m.description, response.body
  end

  def test_show_members_get
    # arrange
    mm = create(:microcosm_member)
    # act
    get members_of_microcosm_path(mm.microcosm)
    # assert
    check_page_basics
    assert_match mm.user.display_name, response.body
  end

  def test_show_events_get
    # arrange
    e = create(:event)
    # act
    get events_of_microcosm_path(e.microcosm)
    # assert
    check_page_basics
    assert_match e.title, response.body
  end

  def test_edit_get_no_session
    # arrange
    m = create(:microcosm)
    # act
    get edit_microcosm_path(m)
    # assert
    assert_response :redirect
    assert_redirected_to :controller => :users, :action => :login, :referer => "/microcosms/#{m.slug}/edit"
  end

  def test_edit_get_is_not_member_is_not_organizer
    # arrange
    m = create(:microcosm)
    user = create(:user)
    session_for(user)
    # act
    get edit_microcosm_path(m)
    # assert
    follow_redirect!
    assert_response :forbidden
  end

  def test_edit_get_is_member_not_organizer
    # arrange
    mm = create(:microcosm_member)
    session_for(mm.user)
    # act
    get edit_microcosm_path(mm.microcosm)
    # assert
    follow_redirect!
    assert_response :forbidden
  end

  def test_edit_get_is_organizer
    # arrange
    mm = create(:microcosm_member, :organizer)
    # We need to reload the object from PG because the floats in Ruby translate
    # to double precision in PG and will actually loose 1 digit of precision.  PG
    # says 15, but it doesn't get that.  Reload so values below are correct.
    mm.reload
    session_for(mm.user)
    # act
    get edit_microcosm_path(mm.microcosm)
    # assert
    check_page_basics
    assert_select "div#content", :count => 1 do
      assert_select "form[action='/microcosms/#{mm.microcosm.slug}'][method=post]", :count => 1 do
        assert_select "input#microcosm_location[name='microcosm[location]'][value='#{mm.microcosm.location}']", :count => 1
        assert_select "input#microcosm_latitude[name='microcosm[latitude]'][value='#{mm.microcosm.latitude}']", :count => 1
        assert_select "input#microcosm_longitude[name='microcosm[longitude]'][value='#{mm.microcosm.longitude}']", :count => 1
        assert_select "input#microcosm_min_lat[name='microcosm[min_lat]'][value='#{mm.microcosm.min_lat}']", :count => 1
        assert_select "input#microcosm_max_lat[name='microcosm[max_lat]'][value='#{mm.microcosm.max_lat}']", :count => 1
        assert_select "input#microcosm_min_lon[name='microcosm[min_lon]'][value='#{mm.microcosm.min_lon}']", :count => 1
        assert_select "input#microcosm_max_lon[name='microcosm[max_lon]'][value='#{mm.microcosm.max_lon}']", :count => 1
        assert_select "textarea#microcosm_description[name='microcosm[description]']", :text => mm.microcosm.description, :count => 1
        assert_select "input", :count => 11
      end
    end
  end

  def test_update_put_success
    # arrange
    mm = create(:microcosm_member, :organizer)
    session_for(mm.user)
    m1 = mm.microcosm # original object
    m2 = build(:microcosm) # new data

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

  # Not sure how to get this to fail.  "apple" is type_cast'ed to 0.  update() doesn't
  # return falsy?
  # def test_update_put_failure
  #   # arrange
  #   mm = create(:microcosm_member, :organizer)
  #   session_for(mm.user)
  #   m1 = mm.microcosm # original object
  #   m1.latitude = "apple"
  #   # act
  #   put microcosm_url(m1), params: {:microcosm => m1.as_json}, xhr: true
  #   # assert
  #   assert_equal I18n.t("microcosms.update.failure"), flash[:notice]
  #   assert_template "microcosms/edit"
  # end

  def test_new_no_login
    # Make sure that you are redirected to the login page when you
    # are not logged in
    # act
    get new_microcosm_path
    # assert
    assert_response :redirect
    assert_redirected_to :controller => :users, :action => :login, :referer => "/microcosms/new"
  end

  def test_new_form
    # Now try again when logged in
    # arrange
    session_for(create(:user))
    # act
    get new_microcosm_path
    # assert
    check_page_basics
    assert_select "title", :text => /New Microcosm/, :count => 1
    assert_select "div.content-heading", :count => 1 do
      assert_select "h1", :text => /New Microcosm/, :count => 1
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

  # also tests add_first_organizer
  def test_create
    # arrange
    u = create(:user)
    session_for(u)
    m_orig = create(:microcosm)

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
    assert_equal m_new.organizers[0].user, u
  end

  def test_step_up_non_member
    # arrange
    u = create(:user)
    session_for(u)
    m = create(:microcosm)
    # act
    post step_up_url(m)
    follow_redirect!
    # assert
    assert_equal "Only members can step up.", flash[:notice]
  end

  def test_step_up_member
    # arrange
    mm = create(:microcosm_member)
    session_for(mm.user)
    # act
    post step_up_url(mm.microcosm)
    follow_redirect!
    # assert
    assert_equal "You have stepped up.", flash[:notice]
  end

  def test_step_up_already_has_organizer
    # arrange
    mm = create(:microcosm_member, :organizer)
    session_for(mm.user)
    # act
    post step_up_url(mm.microcosm)
    follow_redirect!
    # assert
    assert_equal "This microcosm already has an organizer.", flash[:notice]
  end
end
