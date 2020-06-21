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
    assert_match e.location, response.body
  end

end
