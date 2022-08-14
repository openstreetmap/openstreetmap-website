require "test_helper"

class MicrocosmsControllerTest < ActionDispatch::IntegrationTest
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/microcosms/1", :method => :get },
      { :controller => "microcosms", :action => "show", :id => "1" }
    )
    assert_routing(
      { :path => "/microcosms/mdc", :method => :get },
      { :controller => "microcosms", :action => "show_by_key", :key => "mdc" }
    )
  end

  def test_show_get
    m = create(:microcosm)
    get microcosm_path(m)
    check_page_basics
    assert_template("show")
    assert_match m.name, response.body
    assert_match m.description, response.body
  end

  def test_show_by_key_get
    m = create(:microcosm)
    get microcosm_show_by_key_path(m.key)
    check_page_basics
    assert_template("show")
    assert_match m.name, response.body
    assert_match m.description, response.body
  end
end
