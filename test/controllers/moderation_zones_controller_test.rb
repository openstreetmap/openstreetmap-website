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

  test "new, as normal user" do
    session_for(create(:user))
    get new_moderation_zone_url
    assert_redirected_to "/403"
  end

  test "new, as moderator" do
    session_for(create(:moderator_user))
    get new_moderation_zone_url
    assert_response :success
    assert_dom "input[name='moderation_zone[expiry_type]'][value='relative'][checked]"
  end

  test "create, unauthenticated" do
    post(
      moderation_zones_url,
      :params => { :moderation_zone => {} }
    )
    assert_response :forbidden
  end

  test "create, as normal user" do
    session_for(create(:user))
    post(
      moderation_zones_url,
      :params => {
        :moderation_zone => {
          **attributes_for(:moderation_zone)
            .slice(:name, :reason, :zone),
          :expiry_type => "relative",
          :period => 2.days.in_hours.to_i
        }
      }
    )
    assert_redirected_to "/403"
  end

  test "create, as moderator" do
    moderator = create(:moderator_user)
    session_for(moderator)

    assert_difference("ModerationZone.count") do
      post(
        moderation_zones_url,
        :params => {
          :moderation_zone => {
            **attributes_for(:moderation_zone)
              .slice(:name, :reason, :zone),
            :expiry_type => "relative",
            :period => 2.days.in_hours.to_i
          }
        }
      )
    end

    moderation_zone = ModerationZone.last
    assert_redirected_to moderation_zones_url

    assert_in_delta moderation_zone.ends_at, 2.days.from_now, 10.seconds
  end

  test "create with an exact expiration time" do
    session_for(create(:moderator_user))
    ends_at = 2.days.from_now.change(:hour => 14, :min => 30, :sec => 0)

    assert_difference("ModerationZone.count") do
      post(
        moderation_zones_url,
        :params => {
          :moderation_zone => {
            **attributes_for(:moderation_zone).slice(:name, :reason, :zone),
            :expiry_type => "absolute",
            :ends_at => ends_at.strftime("%Y-%m-%dT%H:%M")
          }
        }
      )
    end

    assert_redirected_to moderation_zones_url
    assert_equal ends_at.to_i, ModerationZone.last.ends_at.to_i
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
            :expiry_type => "relative",
            :period => 6.months.in_hours.to_i
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

  test "edit, as normal user" do
    session_for(create(:user))
    moderation_zone = create(:moderation_zone, :ends_at => 1.year.from_now)
    get edit_moderation_zone_url(moderation_zone)
    assert_redirected_to "/403"
  end

  test "edit, as moderator" do
    session_for(create(:moderator_user))
    moderation_zone = create(:moderation_zone, :ends_at => 1.year.from_now)
    get edit_moderation_zone_url(moderation_zone)
    assert_response :success
    assert_dom "input[name='moderation_zone[expiry_type]'][value='absolute'][checked]"
    assert_dom "input[name='moderation_zone[ends_at]']" do |nodes|
      assert_equal moderation_zone.ends_at.beginning_of_minute, Time.zone.parse(nodes.first["value"]).utc
    end
  end

  test "update, unauthenticated" do
    patch(
      moderation_zone_url(123),
      :params => { :moderation_zone => {} }
    )
    assert_response :forbidden
  end

  test "update, as normal user" do
    # This is an edge case: a normal user has a moderation zone to their name.
    # Perhaps they used to be a moderator, but no longer. The important
    # bit is that they shouldn't be able to update it any more.
    #
    # Instead of this we could just have a test for "normal user can't update"
    # with a simpler request (eg: with empty params) but, for the sake of
    # doing it properly, let's have everything in place except for the only detail
    # that the user is not a moderator.
    creator = create(:user)
    moderation_zone = create(:moderation_zone, :ends_at => 1.week.from_now, :creator => creator)
    session_for(creator)

    patch(
      moderation_zone_url(moderation_zone),
      :params => {
        :moderation_zone => {
          :name => moderation_zone.name,
          :reason => moderation_zone.reason,
          :zone => moderation_zone.zone,
          :expiry_type => "relative",
          :period => 2.weeks.in_hours.to_i
        }
      }
    )
    assert_redirected_to "/403"
  end

  test "update, as moderator" do
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
          :expiry_type => "relative",
          :period => 2.weeks.in_hours.to_i
        }
      }
    )
    assert_redirected_to moderation_zones_url

    moderation_zone.reload
    assert_in_delta moderation_zone.ends_at, 2.weeks.from_now, 10.seconds
    assert_nil moderation_zone.revoker
  end

  test "update, preserving the exact expiration time" do
    creator = create(:moderator_user)
    ends_at = 2.days.from_now.change(:hour => 14, :min => 30, :sec => 0)
    moderation_zone = create(:moderation_zone, :ends_at => ends_at, :creator => creator)
    session_for(creator)

    patch(
      moderation_zone_url(moderation_zone),
      :params => {
        :moderation_zone => {
          :name => "Updated name",
          :expiry_type => "absolute",
          :ends_at => ends_at.strftime("%Y-%m-%dT%H:%M")
        }
      }
    )

    assert_redirected_to moderation_zones_url
    assert_equal "Updated name", moderation_zone.reload.name
    assert_equal ends_at.to_i, moderation_zone.ends_at.to_i
  end

  test "update ignores period when expiry_type is absolute" do
    creator = create(:moderator_user)
    ends_at = 3.days.from_now.change(:hour => 9, :min => 15, :sec => 0)
    moderation_zone = create(:moderation_zone, :ends_at => 1.week.from_now, :creator => creator)
    session_for(creator)

    patch(
      moderation_zone_url(moderation_zone),
      :params => {
        :moderation_zone => {
          :expiry_type => "absolute",
          :period => 1.year.in_hours.to_i,
          :ends_at => ends_at.strftime("%Y-%m-%dT%H:%M")
        }
      }
    )

    assert_redirected_to moderation_zones_url
    assert_equal ends_at.to_i, moderation_zone.reload.ends_at.to_i
  end

  test "update, of an inactive zone, ignores a new (still past) ends_at" do
    creator = create(:moderator_user)
    original_ends_at = 2.weeks.ago
    moderation_zone = create(:moderation_zone, :creator => creator, :ends_at => original_ends_at)
    session_for(creator)

    patch(
      moderation_zone_url(moderation_zone),
      :params => {
        :moderation_zone => {
          :name => "Updated name",
          :expiry_type => "absolute",
          :ends_at => 1.week.ago.strftime("%Y-%m-%dT%H:%M")
        }
      }
    )

    assert_redirected_to moderation_zones_url
    assert_nil flash[:error]

    moderation_zone.reload
    assert_equal "Updated name", moderation_zone.name
    assert_equal original_ends_at.to_i, moderation_zone.ends_at.to_i
    assert_not_predicate moderation_zone, :active?
  end

  test "update, without period" do
    creator = create(:moderator_user)
    moderation_zone = create(:moderation_zone, :ends_at => 1.week.from_now, :creator => creator)
    initial_ends_at = moderation_zone.ends_at
    session_for(creator)

    patch(
      moderation_zone_url(moderation_zone),
      :params => {
        :moderation_zone => {
          :name => "New name!",
          :expiry_type => "relative"
        }
      }
    )
    assert_response :bad_request

    moderation_zone.reload
    assert_nil moderation_zone.revoker
    assert_equal initial_ends_at, moderation_zone.ends_at
  end

  test "update, without ends_at" do
    creator = create(:moderator_user)
    moderation_zone = create(:moderation_zone, :ends_at => 1.week.from_now, :creator => creator)
    initial_ends_at = moderation_zone.ends_at
    session_for(creator)

    patch(
      moderation_zone_url(moderation_zone),
      :params => {
        :moderation_zone => {
          :name => "New name!",
          :expiry_type => "absolute"
        }
      }
    )
    assert_response :bad_request

    moderation_zone.reload
    assert_nil moderation_zone.revoker
    assert_equal initial_ends_at, moderation_zone.ends_at
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
          :expiry_type => "relative",
          :period => 4.days.in_hours.to_i
        }
      }
    )

    assert_response :unprocessable_content
    assert_dom "option[selected]", :text => "4 days"
  end

  test "update to revoke" do
    revoker = create(:moderator_user)
    moderation_zone = create(:moderation_zone, :ends_at => 1.week.from_now)
    session_for(revoker)

    patch(
      moderation_zone_url(moderation_zone),
      :params => {
        :moderation_zone => {
          :name => moderation_zone.name,
          :reason => moderation_zone.reason,
          :zone => moderation_zone.zone,
          :expiry_type => "relative",
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
    moderation_zone = create(:moderation_zone, :reason => "Initial reason", :ends_at => 1.week.ago)
    session_for(updater)

    patch(
      moderation_zone_url(moderation_zone),
      :params => {
        :moderation_zone => {
          :reason => "Updated reason",
          :expiry_type => "relative",
          :period => 0
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
    original_ends_at = moderation_zone.ends_at
    session_for(creator)

    patch(
      moderation_zone_url(moderation_zone),
      :params => {
        :moderation_zone => {
          :reason => "Updated reason",
          :expiry_type => "relative",
          :period => 0
        }
      }
    )

    assert_redirected_to moderation_zones_url
    assert_nil flash[:error]

    moderation_zone.reload
    assert_equal "Updated reason", moderation_zone.reason
    assert_equal original_ends_at, moderation_zone.ends_at
  end

  test "update, by non-creator, of revoked record" do
    updater = create(:moderator_user)
    revoker = create(:moderator_user)
    moderation_zone = create(:moderation_zone, :reason => "Initial reason", :ends_at => 1.week.ago, :revoker => revoker)
    session_for(updater)

    patch(
      moderation_zone_url(moderation_zone),
      :params => {
        :moderation_zone => {
          :reason => "Updated reason",
          :expiry_type => "relative",
          :period => 0
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
    moderation_zone = create(:moderation_zone, :reason => "Initial reason", :ends_at => 1.week.from_now)
    session_for(updater)

    patch(
      moderation_zone_url(moderation_zone),
      :params => {
        :moderation_zone => {
          :reason => "Updated reason",
          :expiry_type => "relative",
          :period => 1.week.in_hours.to_i
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
          :expiry_type => "relative",
          :period => 1.week.in_hours.to_i
        }
      }
    )
    assert_redirected_to moderation_zones_url
    assert_equal "This moderation zone is inactive and cannot be reactivated.", flash[:error]

    moderation_zone.reload
    assert_not_predicate moderation_zone, :active?
  end
end
