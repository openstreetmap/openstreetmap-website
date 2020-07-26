require "test_helper"
require "minitest/mock"

class EventAttendancesControllerTest < ActionDispatch::IntegrationTest
  ##
  # test all routes which lead to this controller
  # Following guidance from Ruby on Rails Guide
  # https://guides.rubyonrails.org/testing.html#functional-tests-for-your-controllers
  #
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

  # TODO: Factor this out.
  def check_page_basics
    assert_response :success
    assert_no_missing_translations
  end

  also tests add_first_organizer
  def test_create_when_save_works
    # arrange
    mm = create(:microcosm_member)
    ev = create(:event, :microcosm => mm.microcosm)
    ea_orig = build(:event_attendance, :user => mm.user, :event => ev)
    session_for(mm.user)

    # act
    assert_difference "EventAttendance.count", 1 do
      post event_attendances_url, :params => { :event_attendance => ea_orig.as_json }, :xhr => true
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

  def test_create_when_non_member
    # arrange
    m = create(:microcosm)
    u = create(:user)
    ev = create(:event, :microcosm => m)
    ea_orig = build(:event_attendance, :user => u, :event => ev)
    session_for(u)

    # act
    assert_difference "EventAttendance.count", 0 do
      post event_attendances_url, :params => { :event_attendance => ea_orig.as_json }, :xhr => true
    end

    # assert
    follow_redirect!
    assert_response :forbidden
  end

  def test_create_when_save_fails
    # arrange
    mm = create(:microcosm_member, :organizer)
    session_for(mm.user)

    e = create(:event, :microcosm => mm.microcosm)
    ea = create(:event_attendance, :event => e)
    # Customize this instance.
    def ea.save
      false
    end

    controller_mock = EventAttendancesController.new
    def controller_mock.render(_partial)
      # TODO: Would be nice to verify :new was rendered.
    end

    # act
    EventAttendancesController.stub :new, controller_mock do
      EventAttendance.stub :new, ea do
        assert_difference "EventAttendance.count", 0 do
          post event_attendances_url, :params => { :event_attendance => ea.as_json }, :xhr => true
        end
      end
    end

    # assert
    assert_equal I18n.t("event_attendances.create.failure"), flash[:alert]
  end
end
