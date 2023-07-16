require "test_helper"

class EventAttendancesControllerTest < ActionDispatch::IntegrationTest
  def test_routes
    assert_routing(
      { :path => "/event_attendances/1", :method => :put },
      { :controller => "event_attendances", :action => "update", :id => "1" }
    )
    assert_routing(
      { :path => "/event_attendances", :method => :post },
      { :controller => "event_attendances", :action => "create" }
    )
  end

  def test_create_when_save_works
    # arrange
    cm = create(:community_member)
    ev = create(:event, :community => cm.community)
    ea_orig = build(:event_attendance, :user => cm.user, :event => ev)
    form = ea_orig.attributes.except("id", "created_at", "updated_at")
    session_for(cm.user)

    # act
    assert_difference "EventAttendance.count", 1 do
      post event_attendances_url, :params => { :event_attendance => form.as_json }, :xhr => true
    end

    # assert
    assert_redirected_to event_path(ev)
    ea_new_id = EventAttendance.maximum(:id)
    assert_equal I18n.t("event_attendances.create.success"), flash[:notice]
    ea_new = EventAttendance.find(ea_new_id)
    # Assign the new id to the original object, so we can do an equality test easily.
    ea_orig.id = ea_new.id
    assert_equal(ea_orig, ea_new)
  end

  def test_update_as_wrong_user
    # arrange
    cm = create(:community_member)
    ev = create(:event, :community => cm.community)
    ea1 = create(:event_attendance, :user => cm.user, :event => ev) # original object
    u2 = create(:user)
    ea2 = build(:event_attendance, :user => u2, :event => ev) # new data
    form = ea2.attributes.except("id", "created_at", "updated_at")
    session_for(u2)

    # act
    # Update ea1 with the values from ea2.
    put event_attendance_url(ea1), :params => { :event_attendance => form }, :xhr => true

    # assert
    follow_redirect!
    assert_response :forbidden
  end

  def test_create_when_save_fails
    # arrange
    cm = create(:community_member, :organizer)
    session_for(cm.user)

    e = create(:event, :community => cm.community)
    ea = build(:event_attendance, :event => e, :user => cm.user, :intention => "Invalid")
    form = ea.attributes.except("id", "created_at", "updated_at")

    # act and assert
    assert_no_difference "EventAttendance.count", 0 do
      post event_attendances_path, :params => { :event_attendance => form }
    end
  end

  def test_update_success
    # arrange
    cm = create(:community_member)
    ev = create(:event, :community => cm.community)
    ea1 = create(:event_attendance, :user => cm.user, :event => ev, :intention => "Yes") # original object
    ea2 = build(:event_attendance, :user => cm.user, :event => ev, :intention => "No") # new data
    form = ea2.attributes.except("id", "created_at", "updated_at")
    session_for(cm.user)

    # act
    # Update m1 with the values from m2.
    put event_attendance_url(ea1), :params => { :event_attendance => form.as_json }, :xhr => true

    # assert
    assert_redirected_to event_path(ev)
    assert_equal I18n.t("event_attendances.update.success"), flash[:notice]
    ea1.reload
    # Assign the id of object 1 to object 2, so we can do an equality test easily.
    ea2.id = ea1.id
    assert_equal(ea2, ea1)
  end

  def test_update_when_save_fails
    # arrange
    cm = create(:community_member)
    ev = create(:event, :community => cm.community)
    session_for(cm.user)

    ea = create(:event_attendance, :user => cm.user, :event => ev) # original object
    form = ea.attributes.except("id", "created_at", "updated_at")
    form["intention"] = "Invalid" # Force "save" to fail.

    # act
    assert_difference "EventAttendance.count", 0 do
      put event_attendance_url(ea), :params => { :event_attendance => form.as_json }, :xhr => true
    end

    # assert
    follow_redirect!
    assert_equal I18n.t("event_attendances.update.failure"), flash[:alert]
  end
end
