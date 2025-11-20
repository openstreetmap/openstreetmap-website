# frozen_string_literal: true

require "test_helper"

class RelationMembersControllerTest < ActionDispatch::IntegrationTest
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/relation/1/members", :method => :get },
      { :controller => "relation_members", :action => "show", :id => "1" }
    )
  end

  def test_show_with_members
    relation = create(:relation)
    get relation_members_path(relation)
    assert_response :success
  end

  def test_show_not_found
    get relation_members_path(0)

    assert_response :not_found
  end

  def test_show_timeout
    relation = create(:relation)

    with_settings(:web_timeout => -1) do
      get relation_members_path(relation, 1)
    end

    assert_response :error
  end
end
