require "test_helper"

module Api
  module OldNodes
    class RedactionsControllerTest < ActionDispatch::IntegrationTest
      ##
      # test all routes which lead to this controller
      def test_routes
        assert_routing(
          { :path => "/api/0.6/node/1/2/redaction", :method => :post },
          { :controller => "api/old_nodes/redactions", :action => "create", :node_id => "1", :version => "2" }
        )
        assert_routing(
          { :path => "/api/0.6/node/1/2/redaction", :method => :delete },
          { :controller => "api/old_nodes/redactions", :action => "destroy", :node_id => "1", :version => "2" }
        )

        assert_recognizes(
          { :controller => "api/old_nodes/redactions", :action => "create", :node_id => "1", :version => "2", :allow_delete => true },
          { :path => "/api/0.6/node/1/2/redact", :method => :post }
        )
      end

      ##
      # test that, even as moderator, the current version of a node
      # can't be redacted.
      def test_create_on_current_version
        node = create(:node, :with_history, :version => 2)
        old_node = node.old_nodes.find_by(:version => 2)
        redaction = create(:redaction)
        auth_header = bearer_authorization_header create(:moderator_user)

        post api_node_version_redaction_path(*old_node.id), :params => { :redaction => redaction.id }, :headers => auth_header

        assert_response :bad_request, "shouldn't be OK to redact current version as moderator."
        assert_nil old_node.reload.redaction
      end

      def test_create_without_redaction_id
        node = create(:node, :with_history, :version => 2)
        old_node = node.old_nodes.find_by(:version => 1)
        auth_header = bearer_authorization_header create(:moderator_user)

        post api_node_version_redaction_path(*old_node.id), :headers => auth_header

        assert_response :bad_request, "should need redaction ID to redact."
        assert_nil old_node.reload.redaction
      end

      ##
      # test the redaction of an old version of a node, while not being
      # authorised.
      def test_create_by_unauthorised
        node = create(:node, :with_history, :version => 2)
        old_node = node.old_nodes.find_by(:version => 1)
        redaction = create(:redaction)

        post api_node_version_redaction_path(*old_node.id), :params => { :redaction => redaction.id }

        assert_response :unauthorized, "should need to be authenticated to redact."
        assert_nil old_node.reload.redaction
      end

      def test_create_by_normal_user_without_write_redactions_scope
        node = create(:node, :with_history, :version => 2)
        old_node = node.old_nodes.find_by(:version => 1)
        redaction = create(:redaction)
        auth_header = bearer_authorization_header create(:user), :scopes => %w[read_prefs write_api]

        post api_node_version_redaction_path(*old_node.id), :params => { :redaction => redaction.id }, :headers => auth_header

        assert_response :forbidden, "should need to be moderator to redact."
        assert_nil old_node.reload.redaction
      end

      def test_create_by_normal_user_with_write_redactions_scope
        node = create(:node, :with_history, :version => 2)
        old_node = node.old_nodes.find_by(:version => 1)
        redaction = create(:redaction)
        auth_header = bearer_authorization_header create(:user), :scopes => %w[write_redactions]

        post api_node_version_redaction_path(*old_node.id), :params => { :redaction => redaction.id }, :headers => auth_header

        assert_response :forbidden, "should need to be moderator to redact."
        assert_nil old_node.reload.redaction
      end

      def test_create_by_moderator_without_write_redactions_scope
        node = create(:node, :with_history, :version => 2)
        old_node = node.old_nodes.find_by(:version => 1)
        redaction = create(:redaction)
        auth_header = bearer_authorization_header create(:moderator_user), :scopes => %w[read_prefs write_api]

        post api_node_version_redaction_path(*old_node.id), :params => { :redaction => redaction.id }, :headers => auth_header

        assert_response :forbidden, "should need to have write_redactions scope to redact."
        assert_nil old_node.reload.redaction
      end

      def test_create_by_moderator_with_write_redactions_scope
        node = create(:node, :with_history, :version => 2)
        old_node = node.old_nodes.find_by(:version => 1)
        redaction = create(:redaction)
        auth_header = bearer_authorization_header create(:moderator_user), :scopes => %w[write_redactions]

        post api_node_version_redaction_path(*old_node.id), :params => { :redaction => redaction.id }, :headers => auth_header

        assert_response :success, "should be OK to redact old version as moderator with write_redactions scope."
        assert_equal redaction, old_node.reload.redaction
      end

      ##
      # test the unredaction of an old version of a node, while not being
      # authorised.
      def test_destroy_by_unauthorised
        node = create(:node, :with_history, :version => 2)
        old_node = node.old_nodes.find_by(:version => 1)
        redaction = create(:redaction)
        old_node.redact!(redaction)

        delete api_node_version_redaction_path(*old_node.id)

        assert_response :unauthorized, "should need to be authenticated to unredact."
        assert_equal redaction, old_node.reload.redaction
      end

      ##
      # test the unredaction of an old version of a node, while being
      # authorised as a normal user.
      def test_destroy_by_normal_user
        node = create(:node, :with_history, :version => 2)
        old_node = node.old_nodes.find_by(:version => 1)
        redaction = create(:redaction)
        old_node.redact!(redaction)
        auth_header = bearer_authorization_header

        delete api_node_version_redaction_path(*old_node.id), :headers => auth_header

        assert_response :forbidden, "should need to be moderator to unredact."
        assert_equal redaction, old_node.reload.redaction
      end

      ##
      # test the unredaction of an old version of a node, while being
      # authorised as a moderator.
      def test_destroy_by_moderator
        node = create(:node, :with_history, :version => 2)
        old_node = node.old_nodes.find_by(:version => 1)
        old_node.redact!(create(:redaction))
        auth_header = bearer_authorization_header create(:moderator_user)

        delete api_node_version_redaction_path(*old_node.id), :headers => auth_header

        assert_response :success, "should be OK to unredact old version as moderator."
        assert_nil old_node.reload.redaction
      end

      def test_destroy_at_legacy_route
        node = create(:node, :with_history, :version => 2)
        old_node = node.old_nodes.find_by(:version => 1)
        old_node.redact!(create(:redaction))
        auth_header = bearer_authorization_header create(:moderator_user)

        post "/api/0.6/node/#{old_node.node_id}/#{old_node.version}/redact", :headers => auth_header

        assert_response :success, "should be OK to unredact old version as moderator."
        assert_nil old_node.reload.redaction
      end
    end
  end
end
