# frozen_string_literal: true

require "test_helper"

module Users
  class HeatmapsControllerTest < ActionDispatch::IntegrationTest
    ##
    # test all routes which lead to this controller
    def test_routes
      assert_routing(
        { :path => "/user/username/heatmap", :method => :get },
        { :controller => "users/heatmaps", :action => "show", :user_display_name => "username" }
      )
    end

    def test_show_data
      user = create(:user)
      # Create two changesets
      create(:changeset, :user => user, :created_at => 6.months.ago, :num_changes => 10)
      create(:changeset, :user => user, :created_at => 3.months.ago, :num_changes => 20)

      get user_heatmap_path(user)

      assert_response :success
      # The data should not be empty
      heatmap_data = assigns(:heatmap_data)
      assert_not_nil heatmap_data
      assert_predicate heatmap_data[:data], :any?
      # The data should be in the right format
      heatmap_data[:data].each_value do |entry|
        assert_equal [:date, :max_id, :total_changes], entry.keys.sort, "Heatmap data entries should have expected keys"
      end
      assert_equal 30, heatmap_data[:count]
    end

    def test_show_data_caching
      # Enable caching to be able to test
      Rails.cache.clear
      @original_cache_store = Rails.cache
      Rails.cache = ActiveSupport::Cache::MemoryStore.new

      user = create(:user)

      # Create an initial changeset
      create(:changeset, :user => user, :created_at => 6.months.ago, :num_changes => 15)

      # First request to populate the cache
      get user_heatmap_path(user)
      first_response_data = assigns(:heatmap_data)
      assert_not_nil first_response_data, "Expected heatmap data to be assigned on the first request"
      assert_equal 1, first_response_data[:data].values.count { |day| day[:total_changes].positive? }, "Expected one entry in the heatmap data"

      # Inspect cache after the first request
      cached_data = Rails.cache.read("heatmap_data_of_user_#{user.id}")
      assert_equal first_response_data, cached_data, "Expected the cache to contain the first response data"

      # Add a new changeset to the database
      create(:changeset, :user => user, :created_at => 3.months.ago, :num_changes => 20)

      # Second request
      get user_heatmap_path(user)
      second_response_data = assigns(:heatmap_data)

      # Confirm that the cache is still being used
      assert_equal first_response_data, second_response_data, "Expected cached data to be returned on the second request"

      # Clear the cache and make a third request to confirm new data is retrieved
      Rails.cache.clear
      get user_heatmap_path(user)
      third_response_data = assigns(:heatmap_data)

      # Ensure the new entry is now included
      assert_equal 2, third_response_data[:data].values.count { |day| day[:total_changes].positive? }, "Expected two entries in the heatmap data after clearing the cache"

      # Reset caching config to defaults
      Rails.cache.clear
      Rails.cache = @original_cache_store
    end

    def test_show_data_no_changesets
      user = create(:user)

      get user_heatmap_path(user)

      assert_response :success
      assert_empty(assigns(:heatmap_data)[:data].values)
      assert_select ".heatmap", :count => 0
    end

    def test_show_data_suspended_user
      user = create(:user, :suspended)
      # Create two changesets
      create(:changeset, :user => user, :created_at => 6.months.ago, :num_changes => 10)
      create(:changeset, :user => user, :created_at => 3.months.ago, :num_changes => 20)

      get user_heatmap_path(user)

      # Should fail for suspended users
      assert_response :not_found

      session_for(create(:administrator_user))

      get user_heatmap_path(user)

      # Should work when requested by an administrator
      assert_response :success
      # The data should not be empty
      heatmap_data = assigns(:heatmap_data)
      assert_not_nil heatmap_data
      assert_predicate heatmap_data[:data], :any?
      # The data should be in the right format
      heatmap_data[:data].each_value do |entry|
        assert_equal [:date, :max_id, :total_changes], entry.keys.sort, "Heatmap data entries should have expected keys"
      end
      assert_equal 30, heatmap_data[:count]
    end

    def test_show_data_deleted_user
      user = create(:user, :deleted)
      # Create two changesets
      create(:changeset, :user => user, :created_at => 6.months.ago, :num_changes => 10)
      create(:changeset, :user => user, :created_at => 3.months.ago, :num_changes => 20)

      get user_heatmap_path(user)

      # Should fail for deleted users
      assert_response :not_found

      session_for(create(:administrator_user))

      get user_heatmap_path(user)

      # Should work when requested by an administrator
      assert_response :success
      # The data should not be empty
      heatmap_data = assigns(:heatmap_data)
      assert_not_nil heatmap_data
      assert_predicate heatmap_data[:data], :any?
      # The data should be in the right format
      heatmap_data[:data].each_value do |entry|
        assert_equal [:date, :max_id, :total_changes], entry.keys.sort, "Heatmap data entries should have expected keys"
      end
      assert_equal 30, heatmap_data[:count]
    end

    def test_show_data_unknown_user
      get user_heatmap_path(:user_display_name => "unknown_user")

      # Should fail for unknown users
      assert_response :not_found

      session_for(create(:administrator_user))

      get user_heatmap_path(:user_display_name => "unknown_user")

      # Should still fail when requested by an administrator
      assert_response :not_found
    end

    def test_show_not_public
      user = create(:user)
      user.update(:public_heatmap => false)

      get user_heatmap_path(user)
      assert_response :not_found

      session_for(create(:user))
      get user_heatmap_path(user)
      assert_response :not_found

      session_for(create(:moderator_user))
      get user_heatmap_path(user)
      assert_response :not_found

      session_for(create(:administrator_user))
      get user_heatmap_path(user)
      assert_response :not_found
    end

    def test_show_rendering_of_user_with_no_changesets
      user_without_changesets = create(:user)

      get user_heatmap_path(user_without_changesets)

      assert_response :success
      assert_select ".heatmap", 0
    end

    def test_show_rendering_of_user_with_changesets
      user = create(:user)
      changeset39 = create(:changeset, :user => user, :created_at => 4.months.ago.beginning_of_day, :num_changes => 39)
      _changeset5 = create(:changeset, :user => user, :created_at => 3.months.ago.beginning_of_day, :num_changes => 5)
      changeset11 = create(:changeset, :user => user, :created_at => 3.months.ago.beginning_of_day, :num_changes => 11)

      get user_heatmap_path(user)

      assert_response :success
      assert_select ".heatmap a", 2

      history_path = user_history_path(user)
      assert_select ".heatmap a[data-date='#{4.months.ago.to_date}'][data-count='39'][href='#{history_path}?before=#{changeset39.id + 1}']"
      assert_select ".heatmap a[data-date='#{3.months.ago.to_date}'][data-count='16'][href='#{history_path}?before=#{changeset11.id + 1}']"
      assert_select ".heatmap [data-date='#{5.months.ago.to_date}']:not([data-count])"
    end

    def test_headline_changeset_zero
      user = create(:user)

      get user_heatmap_path(user)

      assert_response :success
      assert_select "h2.text-body-secondary.fs-5", :count => 0
    end

    def test_headline_changeset_singular
      user = create(:user)
      create(:changeset, :user => user, :created_at => 4.months.ago.beginning_of_day, :num_changes => 1)

      get user_heatmap_path(user)

      assert_response :success
      assert_select "h2.text-body-secondary.fs-5", :text => "1 contribution in the last year"
    end

    def test_headline_changeset_plural
      user = create(:user)
      create(:changeset, :user => user, :created_at => 4.months.ago.beginning_of_day, :num_changes => 12)

      get user_heatmap_path(user)

      assert_response :success
      assert_select "h2.text-body-secondary.fs-5", :text => "12 contributions in the last year"
    end
  end
end
