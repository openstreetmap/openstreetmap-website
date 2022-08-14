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
end
