require "test_helper"

class MicrocosmMemberControllerTest < ActionDispatch::IntegrationTest
  test "test routes" do
    assert_routing(
      { :path => "/microcosm_members", :method => :post },
      { :controller => "microcosm_members", :action => "create" }
    )
    assert_routing(
      { :path => "/microcosm_members/1/edit", :method => :get },
      { :controller => "microcosm_members", :action => "edit", :id => "1" }
    )
    assert_routing(
      { :path => "/microcosm_members/1", :method => :put },
      { :controller => "microcosm_members", :action => "update", :id => "1" }
    )
    assert_routing(
      { :path => "/microcosm_members/new", :method => :get },
      { :controller => "microcosm_members", :action => "new" }
    )
  end

  def test_create
    # arrange
    u = create(:user)
    session_for(u)
    m = create(:microcosm)
    mm_orig = build(:microcosm_member, :microcosm => m, :user => u)

    # act
    assert_difference "MicrocosmMember.count", 1 do
      post microcosm_members_url, :params => { :microcosm_member => mm_orig.as_json }, :xhr => true
    end

    # assert
    # Redirect goes to microcosm, not microcosm_member.
    assert_redirected_to microcosm_path(m)
    # The URL doesn't have the id of the object created, so do this.
    mm_new_id = MicrocosmMember.maximum(:id)

    follow_redirect!
    assert_equal I18n.t("microcosm_members.create.success"), flash[:notice]
    mm_new = MicrocosmMember.find(mm_new_id)
    # Assign the id m_new to m_orig, so we can do an equality test easily.
    mm_orig.id = mm_new.id
    assert_equal(mm_orig, mm_new)
    assert_equal mm_new.user, u
  end

  def test_create_when_save_fails
    # arrange
    u = create(:user)
    session_for(u)
    mm = create(:microcosm_member)
    mm.user_id = rand(100000)
    mm.readonly!

    # act
    # TODO: Don't use hard coded string here.
    assert_difference "MicrocosmMember.count", 0 do
      post microcosm_members_url, :params => { :microcosm_member => mm.as_json }, :xhr => true
    end

    # assert
    # Redirect goes to microcosm, not microcosm_member.
    assert_redirected_to microcosm_path(mm.microcosm)
    follow_redirect!
    assert_equal I18n.t("microcosm_members.create.failure"), flash[:alert]
  end
end
