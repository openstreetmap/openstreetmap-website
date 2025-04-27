# frozen_string_literal: true

require "test_helper"

class RelationsControllerTest < ActionDispatch::IntegrationTest
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/relation/1", :method => :get },
      { :controller => "relations", :action => "show", :id => "1" }
    )
  end

  def test_show
    relation = create(:relation)
    sidebar_browse_check :relation_path, relation.id, "elements/show"
  end

  def test_show_timeout
    relation = create(:relation)
    with_settings(:web_timeout => -1) do
      get relation_path(relation)
    end
    assert_response :error
    assert_template :layout => "map"
    assert_dom "h2", "Timeout Error"
    assert_dom "p", /#{Regexp.quote("the relation with the id #{relation.id}")}/
  end
end
