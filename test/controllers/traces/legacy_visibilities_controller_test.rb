# frozen_string_literal: true

require "test_helper"

module Traces
  class LegacyVisibilitiesControllerTest < ActionDispatch::IntegrationTest
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/traces/mine/legacy_visibility/edit", :method => :get },
        { :controller => "traces/legacy_visibilities", :action => "edit" }
      )
      assert_routing(
        { :path => "/traces/mine/legacy_visibility", :method => :patch },
        { :controller => "traces/legacy_visibilities", :action => "update" }
      )
    end

    def test_edit_requires_login
      get edit_traces_legacy_visibility_path
      assert_redirected_to login_path(:referer => edit_traces_legacy_visibility_path)
    end

    def test_edit_links_back_to_the_trace_lists
      user = create(:user)

      session_for(user)
      get edit_traces_legacy_visibility_path
      assert_response :success
      assert_select "a[href=?]", traces_path
      assert_select "a[href=?]", traces_mine_path
    end

    def test_edit_shows_only_own_legacy_traces
      user = create(:user)
      public_trace = create(:trace, :without_validations, :visibility => "public", :user => user)
      private_trace = create(:trace, :without_validations, :visibility => "private", :user => user)
      trackable_trace = create(:trace, :visibility => "trackable", :user => user)
      identifiable_trace = create(:trace, :visibility => "identifiable", :user => user)
      other_users_trace = create(:trace, :without_validations, :visibility => "public")

      session_for(user)
      get edit_traces_legacy_visibility_path
      assert_response :success
      assert_select "table#trace_list tbody tr", :count => 2
      assert_select "table#trace_list tbody tr a", public_trace.name
      assert_select "table#trace_list tbody tr a", private_trace.name
      assert_select "table#trace_list tbody tr a", :text => trackable_trace.name, :count => 0
      assert_select "table#trace_list tbody tr a", :text => identifiable_trace.name, :count => 0
      assert_select "table#trace_list tbody tr a", :text => other_users_trace.name, :count => 0
    end

    def test_edit_filters_by_visibility_and_date
      user = create(:user)
      old_public = create(:trace, :without_validations, :visibility => "public", :user => user, :timestamp => Date.new(2015, 6, 1))
      create(:trace, :without_validations, :visibility => "private", :user => user, :timestamp => Date.new(2015, 6, 1))
      create(:trace, :without_validations, :visibility => "public", :user => user, :timestamp => Date.new(2022, 6, 1))

      session_for(user)
      get edit_traces_legacy_visibility_path(:visibility => "public", :to => "2020-01-01")
      assert_response :success
      assert_select "table#trace_list tbody tr", :count => 1
      assert_select "table#trace_list tbody tr a", old_public.name
    end

    def test_edit_date_range_includes_both_ends
      user = create(:user)
      trace = create(:trace, :without_validations, :visibility => "public", :user => user, :timestamp => Time.utc(2020, 1, 1, 23, 30))

      session_for(user)
      get edit_traces_legacy_visibility_path(:from => "2020-01-01", :to => "2020-01-01")
      assert_response :success
      assert_select "table#trace_list tbody tr", :count => 1
      assert_select "table#trace_list tbody tr a", trace.name
    end

    def test_edit_paged
      user = create(:user)
      # one trace more than fits on a single page
      create_list(:trace, 20, :without_validations, :visibility => "public", :user => user)
      newest = create(:trace, :without_validations, :visibility => "public", :user => user)
      ids = user.traces.order(:id => :desc).pluck(:id)

      session_for(user)
      get edit_traces_legacy_visibility_path
      assert_response :success
      assert_select "table#trace_list tbody tr", :count => 20
      assert_select "table#trace_list tbody tr a", newest.name
      assert_select "a", :text => "Older Traces", :count => 2
      assert_select "a", :text => "Newer Traces", :count => 0

      get edit_traces_legacy_visibility_path(:before => ids[19])
      assert_response :success
      assert_select "table#trace_list tbody tr", :count => 1
      assert_select "a", :text => "Newer Traces", :count => 2
      assert_select "a", :text => "Older Traces", :count => 0
    end

    def test_edit_with_no_legacy_traces
      user = create(:user)
      create(:trace, :visibility => "trackable", :user => user)

      session_for(user)
      get edit_traces_legacy_visibility_path
      assert_response :success
      assert_select "table#trace_list", :count => 0
    end

    def test_edit_disabled
      with_settings(:traces_disabled => true) do
        get edit_traces_legacy_visibility_path
        assert_response :not_found
      end
    end

    def test_update_requires_login
      patch traces_legacy_visibility_path, :params => { :new_visibility => "identifiable" }
      assert_response :forbidden
    end

    def test_update_changes_matching_traces_only
      user = create(:user)
      old_public = create(:trace, :without_validations, :visibility => "public", :user => user, :timestamp => Date.new(2015, 6, 1))
      old_private = create(:trace, :without_validations, :visibility => "private", :user => user, :timestamp => Date.new(2019, 6, 1))
      recent_public = create(:trace, :without_validations, :visibility => "public", :user => user, :timestamp => Date.new(2022, 6, 1))
      other_users_trace = create(:trace, :without_validations, :visibility => "public", :timestamp => Date.new(2015, 6, 1))

      session_for(user)
      patch traces_legacy_visibility_path, :params => { :visibility => "public", :to => "2020-01-01", :new_visibility => "identifiable" }
      assert_redirected_to edit_traces_legacy_visibility_path(:visibility => "public", :from => nil, :to => "2020-01-01")
      assert_equal "Changed the visibility of 1 trace.", flash[:notice]

      assert_equal "identifiable", old_public.reload.visibility
      assert_equal "private", old_private.reload.visibility
      assert_equal "public", recent_public.reload.visibility
      assert_equal "public", other_users_trace.reload.visibility
    end

    def test_update_counts_every_matching_trace
      user = create(:user)
      create_list(:trace, 3, :without_validations, :visibility => "public", :user => user)

      session_for(user)
      patch traces_legacy_visibility_path, :params => { :new_visibility => "trackable" }
      assert_equal "Changed the visibility of 3 traces.", flash[:notice]
      assert_equal 3, user.traces.where(:visibility => "trackable").count
    end

    def test_update_rejects_legacy_visibility
      user = create(:user)
      trace = create(:trace, :without_validations, :visibility => "public", :user => user)

      session_for(user)
      patch traces_legacy_visibility_path, :params => { :new_visibility => "private" }
      assert_redirected_to edit_traces_legacy_visibility_path(:visibility => nil, :from => nil, :to => nil)
      assert_equal "public", trace.reload.visibility

      patch traces_legacy_visibility_path, :params => { :new_visibility => "" }
      assert_redirected_to edit_traces_legacy_visibility_path(:visibility => nil, :from => nil, :to => nil)
      assert_equal "public", trace.reload.visibility

      patch traces_legacy_visibility_path
      assert_redirected_to edit_traces_legacy_visibility_path(:visibility => nil, :from => nil, :to => nil)
      assert_equal "public", trace.reload.visibility
    end

    def test_update_disabled
      with_settings(:traces_disabled => true) do
        patch traces_legacy_visibility_path, :params => { :new_visibility => "identifiable" }
        assert_response :not_found
      end
    end
  end
end
