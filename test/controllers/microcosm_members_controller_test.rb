require "test_helper"
require "minitest/mock"

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

  def test_create_when_save_works
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

  # This test could also mock controller.save like the other tests.
  def test_create_when_save_fails
    # arrange
    mm = create(:microcosm_member)
    session_for(mm.user)

    mm2 = create(:microcosm_member, :microcosm => mm.microcosm)
    # Customize this instance.
    def mm2.save
      false
    end

    # act
    MicrocosmMember.stub :new, mm2 do
      assert_difference "MicrocosmMember.count", 0 do
        post microcosm_members_url, :params => { :microcosm_member => mm.as_json }, :xhr => true
      end
    end

    # assert
    # Redirect goes to microcosm, not microcosm_member.
    assert_redirected_to microcosm_path(mm.microcosm)
    follow_redirect!
    assert_equal I18n.t("microcosm_members.create.failure"), flash[:alert]
  end

  def test_update_as_a_different_user
    # arrange
    mm = create(:microcosm_member) # N.b. not an organizer
    session_for(create(:user))

    # act
    put microcosm_member_url(mm), :params => { :microcosm_member => mm.as_json }, :xhr => true

    # assert
    follow_redirect!
    assert_response :forbidden
  end

  def test_update_when_save_works
    # arrange
    mm1 = create(:microcosm_member, :organizer) # original
    session_for(mm1.user)
    mm2 = build(:microcosm_member) # new data

    # act
    # Update mm1 with the values from mm2.
    put microcosm_member_url(mm1), :params => { :microcosm_member => mm2.as_json }, :xhr => true

    # assert
    mm1.reload
    # Assign the id of m1 to m2, so we can do an equality test easily.
    mm2.id = mm1.id
    assert_equal(mm2, mm1)
  end

  def test_update_when_save_fails
    # arrange
    mm = create(:microcosm_member, :organizer)
    session_for(mm.user)
    mm.role = "asdf" # assume does not exist

    # act
    put microcosm_member_url(mm), :params => { :microcosm_member => mm.as_json }, :xhr => true

    # assert
    assert_response :success
    assert_template "microcosm_members/edit"
  end

  def test_delete_as_a_different_user
    # arrange
    mm = create(:microcosm_member) # N.b. not an organizer
    session_for(create(:user))

    # act
    delete microcosm_member_url(mm), :xhr => true

    # assert
    follow_redirect!
    assert_response :forbidden
  end

  def test_delete_when_destroy_works
    # arrange
    mm1 = create(:microcosm_member, :organizer) # original
    session_for(mm1.user)
    mm2 = create(:microcosm_member, :microcosm => mm1.microcosm)

    # act
    delete microcosm_member_url(mm2), :xhr => true

    # assert
    mm1.reload
    assert_not mm1.microcosm.member?(mm2.user)
  end

  def test_delete_when_destroy_fails
    # arrange
    mm = create(:microcosm_member, :organizer)
    session_for(mm.user)
    # Customize this instance so delete returns false.
    def mm.destroy
      false
    end

    controller_mock = MicrocosmMembersController.new
    def controller_mock.set_microcosm_member
      @microcosm_member = MicrocosmMember.new
    end

    def controller_mock.render(_partial)
      # Can't do assert_equal here.
      # assert_equal :edit, partial
    end

    # act
    MicrocosmMembersController.stub :new, controller_mock do
      MicrocosmMember.stub :new, mm do
        assert_difference "MicrocosmMember.count", 0 do
          delete microcosm_member_url(mm), :xhr => true
        end
      end
    end

    # assert
    assert_match(/#{I18n.t("microcosm_members.destroy.failure")}/, flash[:error])
  end
end
