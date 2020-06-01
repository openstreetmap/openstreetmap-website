require "test_helper"

class MicrocosmsControllerTest < ActionDispatch::IntegrationTest
  ##
  # test all routes which lead to this controller
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
    m = create(:microcosm)
    get microcosms_path
    check_page_basics
    assert_template "index"
    assert_match m.name, response.body
  end

  def test_show_get
    m = create(:microcosm)
    get microcosm_path(m)
    check_page_basics
    # assert_template("show")
    assert_match m.name, response.body
    assert_match m.description, response.body
  end

  def test_show_members_get
    mm = create(:microcosm_member)
    get members_of_microcosm_path(mm.microcosm)
    check_page_basics
    assert_match mm.user.display_name, response.body
  end

  def test_show_events_get
    e = create(:event)
    get events_of_microcosm_path(e.microcosm)
    check_page_basics
    assert_match e.title, response.body
  end

  def test_edit_get_no_session
    m = create(:microcosm)
    get edit_microcosm_path(m)
    assert_response :redirect
    assert_redirected_to :controller => :users, :action => :login, :referer => "/microcosms/#{m.slug}/edit"
  end

  def test_edit_get_is_not_member_is_not_organizer
    m = create(:microcosm)
    user = create(:user)
    session_for(user)
    get edit_microcosm_path(m)
    follow_redirect!
    assert_response :forbidden
  end

  def test_edit_get_is_member_not_organizer
    mm = create(:microcosm_member)
    session_for(mm.user)
    get edit_microcosm_path(mm.microcosm)
    follow_redirect!
    assert_response :forbidden
  end

  def test_edit_get_is_organizer
    mm = create(:microcosm_member, :organizer)
    # We need to reload the object from PG because the floats in Ruby translate
    # to double precision in PG and will actually loose 1 digit of precision.  PG
    # says 15, but it doesn't get that.  Reload so values below are correct.
    mm.reload
    session_for(mm.user)
    get edit_microcosm_path(mm.microcosm)
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
end
