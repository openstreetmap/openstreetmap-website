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
    cm = create(:community_member)

    get community_community_members_path(cm.community)

    assert_response :success
    assert_template "index"
    assert_match cm.user.display_name, response.body
  end

  def test_index_community_does_not_exist
    get community_community_members_path("does not exist")

    assert_response :not_found
    assert_template "communities/no_such_community"
  end

  def test_create_when_save_works
    c = create_community_with_organizer
    session_for(c.leader)
    u = create(:user)
    cm_orig = build(:community_member, :community => c, :user => u)
    form = cm_orig.attributes.except("id", "created_at", "updated_at")

    assert_difference "CommunityMember.count", 1 do
      post community_members_path, :params => { :community_member => form.as_json }
    end

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
    u = create(:user)
    session_for(u)
    cm = build(:community_member, :community_id => 4200, :user => u)
    form = cm.attributes.except("id", "created_at", "updated_at")

    assert_difference "CommunityMember.count", 0 do
      post community_members_path, :params => { :community_member => form.as_json }
    end

    # Redirect goes to community, not community_member.
    assert_redirected_to communities_path
    follow_redirect!
    assert_equal I18n.t("community_members.create.failure"), flash[:alert]
  end

  def test_update_as_a_different_user
    cm = create(:community_member) # N.b. not an organizer
    session_for(create(:user))

    put community_member_url(cm), :params => { :community_member => cm.as_json }, :xhr => true

    assert_redirected_to :controller => :errors, :action => :forbidden
  end

  def test_update_when_save_works
    cm_orig = create(:community_member, :organizer)
    session_for(cm_orig.user)
    cm_mod = build(:community_member) # new data

    # Update cm_orig with the values from cm_mod.
    put community_member_url(cm_orig), :params => { :community_member => cm_mod.as_json }, :xhr => true

    cm_orig.reload
    # Assign the id of m1 to m2, so we can do an equality test easily.
    cm_mod.id = cm_orig.id
    assert_equal(cm_mod, cm_orig)
  end

  def test_update_when_save_fails
    cm = create(:community_member, :organizer)
    session_for(cm.user)
    form = cm.attributes.except("id", "created_at", "updated_at")
    form[:role] = "asdf" # assume does not exist

    put community_member_url(cm), :params => { :community_member => form.as_json }, :xhr => true

    assert_response :success
    assert_template "community_members/edit"
  end

  def test_delete_as_a_different_user
    cm = create(:community_member) # N.b. not an organizer
    session_for(create(:user))

    delete community_member_url(cm), :xhr => true

    assert_redirected_to :controller => "errors", :action => "forbidden"
  end

  def test_delete_when_destroy_works
    organizer = create(:community_member, :organizer)
    session_for(organizer.user)
    member = create(:community_member, :community => organizer.community)

    delete community_member_url(member), :xhr => true

    organizer.community.reload
    assert_not organizer.community.member?(member.user)
  end

  def test_delete_when_destroy_fails
    cm = create(:community_member, :organizer)
    session_for(cm.user)
    # Customize this instance so delete returns false.
    def cm.destroy
      false
    end

    controller_mock = CommunityMembersController.new
    def controller_mock.set_community_member
      @community_member = CommunityMember.new
    end

    def controller_mock.render(_partial, _msg)
      # Can't do assert_equal here.
      # assert_equal :edit, partial
    end

    CommunityMembersController.stub :new, controller_mock do
      CommunityMember.stub :new, cm do
        assert_difference "CommunityMember.count", 0 do
          delete community_member_url(cm), :xhr => true
        end
      end
    end

    assert_match(/#{I18n.t('community_members.destroy.failure')}/, flash[:error])
  end
end
