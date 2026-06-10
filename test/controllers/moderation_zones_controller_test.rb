# frozen_string_literal: true

require "test_helper"

class ModerationZonesControllerTest < ActionDispatch::IntegrationTest
  test "routes" do
    assert_routing(
      { :path => "/moderation_zones", :method => :get },
      { :controller => "moderation_zones", :action => "index" }
    )
    assert_routing(
      { :path => "/moderation_zones/new", :method => :get },
      { :controller => "moderation_zones", :action => "new" }
    )
    assert_routing(
      { :path => "/moderation_zones/123/edit", :method => :get },
      { :controller => "moderation_zones", :action => "edit", :id => "123" }
    )
    assert_routing(
      { :path => "/moderation_zones", :method => :post },
      { :controller => "moderation_zones", :action => "create" }
    )
    assert_routing(
      { :path => "/moderation_zones/123", :method => :put },
      { :controller => "moderation_zones", :action => "update", :id => "123" }
    )
  end

  test "index, unauthenticated" do
    get moderation_zones_url
    assert_redirected_to login_url(:referer => moderation_zones_path)
  end

  test "index, as normal user" do
    session_for(create(:user))
    get moderation_zones_url
    assert_redirected_to "/403"
  end

  test "index, as moderator" do
    create(:moderation_zone, :ends_at => 1.week.ago)
    create(:moderation_zone, :ends_at => 1.week.from_now)
    revoker = create(:moderator_user, :display_name => "Revokator")
    create(:moderation_zone, :ends_at => 1.week.ago, :revoker => revoker)

    session_for(create(:moderator_user))
    get moderation_zones_url
    assert_response :success
    assert_dom "td", :text => "active"
    assert_dom "td", :text => "ended"
    assert_dom "td", :text => "revoked by Revokator"
  end

  test "new, unauthenticated" do
    get new_moderation_zone_url
    assert_redirected_to login_url(:referer => new_moderation_zone_path)
  end

  test "new" do
    session_for(create(:moderator_user))
    get new_moderation_zone_url
    assert_response :success
  end

  test "create, unauthenticated" do
    post(
      moderation_zones_url,
      :params => { :moderation_zone => {} }
    )
    assert_response :forbidden
  end

  test "create" do
    moderator = create(:moderator_user)
    session_for(moderator)

    assert_difference("ModerationZone.count") do
      post(
        moderation_zones_url,
        :params => {
          :moderation_zone => {
            **attributes_for(:moderation_zone)
              .slice(:name, :reason, :zone),
            :period => 2.days.in_hours
          }
        }
      )
    end

    moderation_zone = ModerationZone.last
    assert_redirected_to moderation_zones_url

    assert_in_delta moderation_zone.ends_at, 2.days.from_now, 10.seconds
  end

  test "create, with errors" do
    moderator = create(:moderator_user)
    session_for(moderator)

    assert_no_difference("ModerationZone.count") do
      post(
        moderation_zones_url,
        :params => {
          :moderation_zone => {
            **attributes_for(:moderation_zone)
              .slice(:name, :zone),
            :period => 6.months.in_hours
          }
        }
      )
    end

    assert_response :unprocessable_content
    assert_dom "option[selected]", :text => "6 months"
  end

  test "edit, unauthenticated" do
    get edit_moderation_zone_url(123)
    assert_redirected_to login_path(:referer => edit_moderation_zone_path(123))
  end

  test "edit" do
    session_for(create(:moderator_user))
    moderation_zone = create(:moderation_zone, :ends_at => 1.year.from_now)
    get edit_moderation_zone_url(moderation_zone)
    assert_response :success
    assert_dom "option[selected]", :text => "1 year"
  end

  test "update, unauthenticated" do
    patch(
      moderation_zone_url(123),
      :params => { :moderation_zone => {} }
    )
    assert_response :forbidden
  end

  test "update" do
    session_for(create(:moderator_user))
    moderation_zone = create(:moderation_zone, :ends_at => 1.week.from_now)

    patch(
      moderation_zone_url(moderation_zone),
      :params => {
        :moderation_zone => {
          :name => moderation_zone.name,
          :reason => moderation_zone.reason,
          :zone => moderation_zone.zone,
          :period => 2.weeks.in_hours
        }
      }
    )
    assert_redirected_to moderation_zones_url

    moderation_zone.reload
    assert_in_delta moderation_zone.ends_at, 2.weeks.from_now, 10.seconds
    assert_nil moderation_zone.revoker
  end

  test "update, with errors" do
    session_for(create(:moderator_user))
    moderation_zone = create(:moderation_zone, :ends_at => 1.week.from_now)

    patch(
      moderation_zone_url(moderation_zone),
      :params => {
        :moderation_zone => {
          :name => moderation_zone.name,
          :reason => "",
          :zone => moderation_zone.zone,
          :period => 4.days.in_hours
        }
      }
    )

    assert_response :unprocessable_content
    assert_dom "option[selected]", :text => "4 days"
  end

  test "update to revoke" do
    creator = create(:moderator_user)
    revoker = create(:moderator_user)
    moderation_zone = create(:moderation_zone, :ends_at => 1.week.from_now, :creator => creator)
    session_for(revoker)

    patch(
      moderation_zone_url(moderation_zone),
      :params => {
        :moderation_zone => {
          :name => moderation_zone.name,
          :reason => moderation_zone.reason,
          :zone => moderation_zone.zone,
          :period => 0
        }
      }
    )
    assert_redirected_to moderation_zones_url

    moderation_zone.reload
    assert_equal revoker, moderation_zone.revoker
  end
end
