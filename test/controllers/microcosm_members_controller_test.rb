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
    mm_new_id = nil
    assert_difference "MicrocosmMember.count", 1 do
      post microcosm_members_url, :params => { :microcosm_member => mm_orig.as_json }, :xhr => true
      # Redirect goes to microcosm, not microcosm_member.
      mm_new_id = MicrocosmMember.maximum(:id)
    end

    # assert
    mm_new = MicrocosmMember.find(mm_new_id)
    # Assign the id m_new to m_orig, so we can do an equality test easily.
    mm_orig.id = mm_new.id
    assert_equal(mm_orig, mm_new)
    assert_equal mm_new.user, u
  end
end
