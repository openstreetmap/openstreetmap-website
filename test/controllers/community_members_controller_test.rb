require "test_helper"
require "minitest/mock"

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
    c = create_community_with_organizer
    session_for(c.leader)
    u = create(:user)
    cm_orig = build(:community_member, :community => c, :user => u)
    form = cm_orig.attributes.except("id", "created_at", "updated_at")

    # act
    assert_difference "CommunityMember.count", 1 do
      post community_members_path, :params => { :community_member => form.as_json }
    end

    # assert
    # Redirect goes to community, not community_member.
    assert_redirected_to community_path(c)
    follow_redirect!
    assert_equal I18n.t("community_members.create.success"), flash[:notice]

    # The URL doesn't have the id of the object created, so do this.
    cm_new_id = CommunityMember.maximum(:id)
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
    cm = build(:community_member, :community_id => 4200, :user => u)
    form = cm.attributes.except("id", "created_at", "updated_at")

    # act
    assert_difference "CommunityMember.count", 0 do
      post community_members_path, :params => { :community_member => form.as_json }
    end

    # assert
    # Redirect goes to community, not community_member.
    assert_redirected_to communities_path
    follow_redirect!
    assert_equal I18n.t("community_members.create.failure"), flash[:alert]
  end

  def test_update_as_a_different_user
    # arrange
    cm = create(:community_member) # N.b. not an organizer
    session_for(create(:user))

    # act
    put community_member_url(cm), :params => { :community_member => cm.as_json }, :xhr => true

    # assert
    follow_redirect!
    assert_response :forbidden
  end

  def test_update_when_save_works
    # arrange
    cm_orig = create(:community_member, :organizer)
    session_for(cm_orig.user)
    cm_mod = build(:community_member) # new data

    # act
    # Update cm_orig with the values from cm_mod.
    put community_member_url(cm_orig), :params => { :community_member => cm_mod.as_json }, :xhr => true

    # assert
    cm_orig.reload
    # Assign the id of m1 to m2, so we can do an equality test easily.
    cm_mod.id = cm_orig.id
    assert_equal(cm_mod, cm_orig)
  end

  def test_update_when_save_fails
    # arrange
    cm = create(:community_member, :organizer)
    session_for(cm.user)
    form = cm.attributes.except("id", "created_at", "updated_at")
    form[:role] = "asdf" # assume does not exist

    # act
    put community_member_url(cm), :params => { :community_member => form.as_json }, :xhr => true

    # assert
    assert_response :success
    assert_template "community_members/edit"
  end
end
