# frozen_string_literal: true

require "test_helper"

class ModerationZonesControllerTest < ActionDispatch::IntegrationTest
  test "index, unauthenticated" do
    get moderation_zones_url
    assert_redirected_to login_url(:referer => moderation_zones_path)
  end

  test "index" do
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
    creator = create(:moderator_user)
    moderation_zone = create(:moderation_zone, :ends_at => 1.week.from_now, :creator => creator)
    session_for(creator)

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
    creator = create(:moderator_user)
    moderation_zone = create(:moderation_zone, :ends_at => 1.week.from_now, :creator => creator)
    session_for(creator)

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

  test "update, by non-creator, of inactive+unrevoked record" do
    updater = create(:moderator_user)
    creator = create(:moderator_user)
    moderation_zone = create(:moderation_zone, :reason => "Initial reason", :creator => creator, :ends_at => 1.week.ago)
    session_for(updater)

    patch(
      moderation_zone_url(moderation_zone),
      :params => {
        :moderation_zone => {
          :reason => "Updated reason"
        }
      }
    )
    assert_redirected_to moderation_zones_url
    assert_equal "Only the moderator who created this moderation zone can edit it.", flash[:error]

    moderation_zone.reload
    assert_equal "Initial reason", moderation_zone.reason
  end

  test "update, by creator, of inactive+revoked record" do
    creator = create(:moderator_user)
    moderation_zone = create(:moderation_zone, :reason => "Initial reason", :creator => creator, :ends_at => 1.week.ago)
    session_for(creator)

    patch(
      moderation_zone_url(moderation_zone),
      :params => {
        :moderation_zone => {
          :reason => "Updated reason"
        }
      }
    )

    assert_redirected_to moderation_zones_url
    assert_nil flash[:error]

    moderation_zone.reload
    assert_equal "Updated reason", moderation_zone.reason
  end

  test "update, by non-creator, of revoked record" do
    updater = create(:moderator_user)
    revoker = create(:moderator_user)
    creator = create(:moderator_user)
    moderation_zone = create(:moderation_zone, :reason => "Initial reason", :creator => creator, :ends_at => 1.week.ago, :revoker => revoker)
    session_for(updater)

    patch(
      moderation_zone_url(moderation_zone),
      :params => {
        :moderation_zone => {
          :reason => "Updated reason"
        }
      }
    )
    assert_redirected_to moderation_zones_url
    assert_equal "Only the moderators who created or revoked this moderation zone can edit it.", flash[:error]

    moderation_zone.reload
    assert_equal "Initial reason", moderation_zone.reason
  end

  test "update, by non-creator, of active record" do
    updater = create(:moderator_user)
    creator = create(:moderator_user)
    moderation_zone = create(:moderation_zone, :reason => "Initial reason", :creator => creator, :ends_at => 1.week.from_now)
    session_for(updater)

    patch(
      moderation_zone_url(moderation_zone),
      :params => {
        :moderation_zone => {
          :reason => "Updated reason",
          :period => 1.week.from_now
        }
      }
    )
    assert_redirected_to moderation_zones_url
    assert_equal "Only the moderator who created this moderation zone can edit it without revoking.", flash[:error]

    moderation_zone.reload
    assert_equal "Initial reason", moderation_zone.reason
  end

  test "update to reactivate" do
    creator = create(:moderator_user)
    moderation_zone = create(:moderation_zone, :creator => creator, :ends_at => 1.week.ago)
    session_for(creator)

    patch(
      moderation_zone_url(moderation_zone),
      :params => {
        :moderation_zone => {
          :period => 1.week.from_now
        }
      }
    )
    assert_redirected_to moderation_zones_url
    assert_equal "This moderation zone is inactive and cannot be reactivated.", flash[:error]

    moderation_zone.reload
    assert_not_predicate moderation_zone, :active?
  end
end
