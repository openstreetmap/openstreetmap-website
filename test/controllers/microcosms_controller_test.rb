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
    assert_template("show")
    assert_match m.name, response.body
    assert_match m.description, response.body
  end
end
