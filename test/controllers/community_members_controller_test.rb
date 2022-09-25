require "test_helper"

class CommunityMembersControllerTest < ActionDispatch::IntegrationTest
  test "test routes" do
    assert_routing(
      { :path => "/community_members", :method => :post },
      { :controller => "community_members", :action => "create" }
    )
    # assert_routing(
    #   { :path => "/community_members/1/edit", :method => :get },
    #   { :controller => "community_members", :action => "edit", :id => "1" }
    # )
    # assert_routing(
    #   { :path => "/community_members/1", :method => :put },
    #   { :controller => "community_members", :action => "update", :id => "1" }
    # )
    # assert_routing(
    #   { :path => "/community_members/new", :method => :get },
    #   { :controller => "community_members", :action => "new" }
    # )
  end

  def test_index
    # arrange
    cm = create(:community_member)
    # act
    get community_community_members_path(cm.community)
    # assert
    assert_response :success
    assert_template "index"
    assert_match cm.user.display_name, response.body
  end

  def test_index_community_does_not_exist
    # act
    get community_community_members_path("dne")
    # assert
    assert_response :not_found
    assert_template "communities/no_such_community"
  end

  def test_create_when_save_works
    # arrange
    u = create(:user)
    session_for(u)
    c = create(:community)
    cm_orig = build(:community_member, :community => c, :user => u)
    form = cm_orig.attributes.except("id", "created_at", "updated_at")

    # act
    cm_new_id = nil
    assert_difference "CommunityMember.count", 1 do
      post community_members_path, :params => { :community_member => form.as_json }
      # Redirect goes to community, not community_member, so get the id by asking the database.
      cm_new_id = CommunityMember.maximum(:id)
    end

    # assert
    cm_new = CommunityMember.find(cm_new_id)
    # Assign the id m_new to m_orig, so we can do an equality test easily.
    cm_orig.id = cm_new.id
    assert_equal(cm_orig, cm_new)
    assert_equal cm_new.user, u
  end

  def test_create_when_save_fails
    # arrange
    u = create(:user)
    session_for(u)
    cm_orig = build(:community_member, :community_id => 4200, :user => u)
    form = cm_orig.attributes.except("id", "created_at", "updated_at")

    # act
    assert_difference "CommunityMember.count", 0 do
      post community_members_path, :params => { :community_member => form.as_json }
    end
  end
end
