require "test_helper"
require "minitest/mock"

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

  def test_index_get_future
    # arrange
    e = create(:event)
    # act
    get events_path
    # assert
    assert_response :success
    assert_template "index"
    assert_match e.title, response.body
  end

  def test_index_get_past
    # arrange
    e = create(:event, :moment => Time.now.utc - 2000)
    # act
    get events_path
    # assert
    assert_response :success
    assert_template "index"
    assert_match e.title, response.body
  end

  def test_index_of_community
    # arrange
    c = create(:community)
    e = create(:event, :community => c)
    # act
    get community_community_events_path(c)
    # assert
    assert_response :success
    assert_template "index"
    assert_match e.title, response.body
  end

  def test_index_community_does_not_exist
    # act
    get community_community_events_path("dne")
    # assert
    assert_response :not_found
    assert_template "communities/no_such_community"
  end

  def test_show_get
    # arrange
    e = create(:event)
    # act
    get event_path(e)
    # assert
    assert_response :success
    # assert_template("show")
    assert_match e.title, response.body
    assert_match e.description, response.body
    assert_match e.location, response.body
  end

  def test_new_no_login
    # Make sure that you are redirected to the login page when you
    # are not logged in.
    # act
    # There must be community to build an event against.
    c = create(:community)
    params = { :event => { :community_id => c.id } }
    get new_event_path(params)
    # assert
    assert_response :redirect
    assert_redirected_to login_path(:referer => new_event_path(:params => params))
  end

  def test_new_form
    # Now try again when logged in.
    # There must be community to build an event against.
    # arrange
    cm = create(:community_member, :organizer)
    session_for(cm.user)
    # act
    get new_event_path(:event => { :community_id => cm.community_id })
    # assert
    assert_response :success
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
        assert_select "input", :count => 9
      end
    end
  end

  def test_new_form_non_organizer
    # Now try again when logged in.  There must be community to build an event against.
    # arrange
    cm = create(:community_member)
    session_for(cm.user)
    # act
    get new_event_path(:event => { :community_id => cm.community_id })
    # assert
    follow_redirect!
    assert_response :forbidden
  end

  # also tests application_controller::nilify
  def test_create_when_save_works
    # arrange
    cm = create(:community_member, :organizer)
    e_orig = build(:event, :community => cm.community)
    session_for(cm.user)

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

  def test_create_as_non_organizer
    # arrange
    cm = create(:community_member)
    ev = build(:event, :community => cm.community)
    session_for(cm.user)

    # act
    assert_difference "Event.count", 0 do
      post events_url, :params => { :event => ev.as_json }, :xhr => true
    end

    # assert
    follow_redirect!
    assert_response :forbidden
  end

  def test_create_when_save_fails
    # arrange
    cm = create(:community_member, :organizer)
    session_for(cm.user)

    ev = create(:event, :community => cm.community)
    # Customize this instance.
    def ev.save
      false
    end

    controller_mock = EventsController.new
    def controller_mock.render(_partial)
      # TODO: Would be nice to verify :new was rendered.
    end

    # act
    EventsController.stub :new, controller_mock do
      Event.stub :new, ev do
        assert_difference "Event.count", 0 do
          post events_url, :params => { :event => ev.as_json }, :xhr => true
        end
      end
    end

    # assert
    # assert_equal I18n.t("events.create.failure"), flash[:alert]
  end

  def test_in_past_warns
    # arrange
    cm = create(:community_member, :organizer)
    session_for(cm.user)
    form = create(:event, :community => cm.community).attributes
    form["moment"] = "1000-01-01T01:01"

    # act
    post events_url, :params => { :event => form }

    # assert
    follow_redirect!
    assert_equal I18n.t("events.show.past"), flash[:warning]
  end
end
