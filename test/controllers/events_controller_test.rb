require "test_helper"

class EventsControllerTest < ActionDispatch::IntegrationTest
  def test_routes
    assert_routing(
      { :path => "/events", :method => :get },
      { :controller => "events", :action => "index" }
    )
    assert_routing(
      { :path => "/events/new", :method => :get },
      { :controller => "events", :action => "new" }
    )
    assert_routing(
      { :path => "/events", :method => :post },
      { :controller => "events", :action => "create" }
    )
    assert_routing(
      { :path => "/events/1", :method => :get },
      { :controller => "events", :action => "show", :id => "1" }
    )
    assert_routing(
      { :path => "/events/1/edit", :method => :get },
      { :controller => "events", :action => "edit", :id => "1" }
    )
    assert_routing(
      { :path => "/events/1", :method => :patch },
      { :controller => "events", :action => "update", :id => "1" }
    )
    # No ability in cancancan yet.
    # assert_routing(
    #     { :path => "/events/1", :method => :delete },
    #     { :controller => "events", :action => "destroy", :id => "1" }
    # )
  end

  def check_page_basics
    assert_response :success
    assert_no_missing_translations
  end

  def test_index_get_future
    # arrange
    e = create(:event)
    # act
    get events_path
    # assert
    check_page_basics
    assert_template "index"
    assert_match e.title, response.body
  end

  def test_index_get_past
    # arrange
    e = create(:event, :moment => Time.now - 1000)
    # act
    get events_path
    # assert
    check_page_basics
    assert_template "index"
    assert_no_match e.title, response.body
  end

  def test_show_get
    # arrange
    e = create(:event)
    # act
    get event_path(e)
    # assert
    check_page_basics
    # assert_template("show")
    assert_match e.title, response.body
    assert_match e.description, response.body
    assert_match e.location, response.body
  end

  def test_new_no_login
    # Make sure that you are redirected to the login page when you
    # are not logged in
    # act
    get new_event_path
    # assert
    assert_response :redirect
    assert_redirected_to :controller => :users, :action => :login, :referer => "/events/new"
  end

  def test_new_form
    # Now try again when logged in
    # arrange
    session_for(create(:user))
    # act
    get new_event_path
    # assert
    check_page_basics
    assert_select "title", :text => /New Event/, :count => 1
    assert_select "div.content-heading", :count => 1 do
      assert_select "h1", :text => /New Event/, :count => 1
    end
    assert_select "div#content", :count => 1 do
      assert_select "form[action='/events'][method=post]", :count => 1 do
        assert_select "input#event_title[name='event[title]']", :count => 1
        assert_select "input#event_moment[name='event[moment]']", :count => 1
        assert_select "input#event_location[name='event[location]']", :count => 1
        assert_select "input#event_location_url[name='event[location_url]']", :count => 1
        assert_select "textarea#event_description[name='event[description]']", :count => 1
        assert_select "input#event_latitude[name='event[latitude]']", :count => 1
        assert_select "input#event_longitude[name='event[longitude]']", :count => 1
        assert_select "input", :count => 8
      end
    end
  end

  # also tests application_controller::nilify
  def test_create
    # arrange
    u = create(:user)
    session_for(u)
    e_orig = create(:event)

    # act
    e_new_id = nil
    assert_difference "Event.count", 1 do
      post events_url, :params => { :event => e_orig.as_json }, :xhr => true
      e_new_id = @response.headers["Location"].split("/")[-1]
    end

    # assert
    e_new = Event.find(e_new_id)
    # Assign the id e_new to e_orig, so we can do an equality test easily.
    e_orig.id = e_new.id
    assert_equal(e_orig, e_new)
  end

  def test_update_put_organizer
    # arrange
    mm = create(:microcosm_member, :organizer)
    session_for(mm.user)
    e1 = create(:event, :microcosm => mm.microcosm) # original object
    e2 = build(:event, :microcosm => mm.microcosm) # new data
    # act
    put event_url(e1), :params => { :event => e2.as_json }, :xhr => true
    # assert
    assert_redirected_to event_path(e1)
    # TODO: Is it better to use t() to translate?
    assert_equal "The event was successfully updated.", flash[:notice]
    e1.reload
    # Assign the id of e1 to e2, so we can do an equality test easily.
    e2.id = e1.id
    assert_equal(e2, e1)
  end

  def test_update_put_non_organizer
    # arrange
    mm = create(:microcosm_member)
    session_for(mm.user)
    e1 = create(:event, :microcosm => mm.microcosm) # original object
    e2 = build(:event, :microcosm => mm.microcosm) # new data
    # act
    put event_url(e1), :params => { :event => e2.as_json }, :xhr => true
    # assert
    assert_redirected_to :controller => :errors, :action => :forbidden
  end
end
