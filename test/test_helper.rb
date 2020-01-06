require "coveralls"
Coveralls.wear!("rails")

# Override the simplecov output message, since it is mostly unwanted noise
module SimpleCov
  module Formatter
    class HTMLFormatter
      def output_message(_result); end
    end
  end
end

# Output both the local simplecov html and the coveralls report
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(
  [SimpleCov::Formatter::HTMLFormatter,
   Coveralls::SimpleCov::Formatter]
)

ENV["RAILS_ENV"] = "test"
require_relative "../config/environment"
require "rails/test_help"
require "webmock/minitest"

WebMock.disable_net_connect!(:allow_localhost => true)

module ActiveSupport
  class TestCase
    include FactoryBot::Syntax::Methods
    include ActiveJob::TestHelper

    ##
    # takes a block which is executed in the context of a different
    # ActionController instance. this is used so that code can call methods
    # on the node controller whilst testing the old_node controller.
    def with_controller(new_controller)
      controller_save = @controller
      begin
        @controller = new_controller
        yield
      ensure
        @controller = controller_save
      end
    end

    ##
    # execute a block with missing translation exceptions suppressed
    def without_i18n_exceptions
      exception_handler = I18n.exception_handler
      begin
        I18n.exception_handler = nil
        yield
      ensure
        I18n.exception_handler = exception_handler
      end
    end

    ##
    # work round minitest insanity that causes it to tell you
    # to use assert_nil to test for nil, which is fine if you're
    # comparing to a nil constant but not if you're comparing
    # an expression that might be nil sometimes
    def assert_equal_allowing_nil(exp, act, msg = nil)
      if exp.nil?
        assert_nil act, msg
      else
        assert_equal exp, act, msg
      end
    end

    ##
    # for some reason assert_equal a, b fails when the relations are
    # actually equal, so this method manually checks the fields...
    def assert_relations_are_equal(a, b)
      assert_not_nil a, "first relation is not allowed to be nil"
      assert_not_nil b, "second relation #{a.id} is not allowed to be nil"
      assert_equal a.id, b.id, "relation IDs"
      assert_equal a.changeset_id, b.changeset_id, "changeset ID on relation #{a.id}"
      assert_equal a.visible, b.visible, "visible on relation #{a.id}, #{a.visible.inspect} != #{b.visible.inspect}"
      assert_equal a.version, b.version, "version on relation #{a.id}"
      assert_equal a.tags, b.tags, "tags on relation #{a.id}"
      assert_equal a.members, b.members, "member references on relation #{a.id}"
    end

    ##
    # for some reason assert_equal a, b fails when the ways are actually
    # equal, so this method manually checks the fields...
    def assert_ways_are_equal(a, b)
      assert_not_nil a, "first way is not allowed to be nil"
      assert_not_nil b, "second way #{a.id} is not allowed to be nil"
      assert_equal a.id, b.id, "way IDs"
      assert_equal a.changeset_id, b.changeset_id, "changeset ID on way #{a.id}"
      assert_equal a.visible, b.visible, "visible on way #{a.id}, #{a.visible.inspect} != #{b.visible.inspect}"
      assert_equal a.version, b.version, "version on way #{a.id}"
      assert_equal a.tags, b.tags, "tags on way #{a.id}"
      assert_equal a.nds, b.nds, "node references on way #{a.id}"
    end

    ##
    # for some reason a==b is false, but there doesn't seem to be any
    # difference between the nodes, so i'm checking all the attributes
    # manually and blaming it on ActiveRecord
    def assert_nodes_are_equal(a, b)
      assert_equal a.id, b.id, "node IDs"
      assert_equal a.latitude, b.latitude, "latitude on node #{a.id}"
      assert_equal a.longitude, b.longitude, "longitude on node #{a.id}"
      assert_equal a.changeset_id, b.changeset_id, "changeset ID on node #{a.id}"
      assert_equal a.visible, b.visible, "visible on node #{a.id}"
      assert_equal a.version, b.version, "version on node #{a.id}"
      assert_equal a.tags, b.tags, "tags on node #{a.id}"
    end

    ##
    # set request headers for HTTP basic authentication
    def basic_authorization(user, pass)
      @request.env["HTTP_AUTHORIZATION"] = format("Basic %{auth}", :auth => Base64.encode64("#{user}:#{pass}"))
    end

    ##
    # set request readers to ask for a particular error format
    def error_format(format)
      @request.env["HTTP_X_ERROR_FORMAT"] = format
    end

    ##
    # Used to check that the error header and the forbidden responses are given
    # when the owner of the changset has their data not marked as public
    def assert_require_public_data(msg = "Shouldn't be able to use API when the user's data is not public")
      assert_response :forbidden, msg
      assert_equal @response.headers["Error"], "You must make your edits public to upload new data", "Wrong error message"
    end

    ##
    # Not sure this is the best response we could give
    def assert_inactive_user(msg = "an inactive user shouldn't be able to access the API")
      assert_response :unauthorized, msg
      # assert_equal @response.headers['Error'], ""
    end

    ##
    # Check for missing translations in an HTML response
    def assert_no_missing_translations(msg = "")
      assert_select "span[class=translation_missing]", false, "Missing translation #{msg}"
    end

    ##
    # execute a block with a given set of HTTP responses stubbed
    def with_http_stubs(stubs_file)
      stubs = YAML.load_file(File.expand_path("../http/#{stubs_file}.yml", __FILE__))
      stubs.each do |url, response|
        stub_request(:get, Regexp.new(Regexp.quote(url))).to_return(:status => response["code"], :body => response["body"])
      end

      yield
    end

    def stub_gravatar_request(email, status = 200, body = nil)
      hash = ::Digest::MD5.hexdigest(email.downcase)
      url = "https://www.gravatar.com/avatar/#{hash}?d=404"
      stub_request(:get, url).and_return(:status => status, :body => body)
    end

    def email_text_parts(message)
      message.parts.each_with_object([]) do |part, text_parts|
        if part.content_type.start_with?("text/")
          text_parts.push(part)
        elsif part.multipart?
          text_parts.concat(email_text_parts(part))
        end
      end
    end

    def sign_in_as(user)
      visit login_path
      fill_in "username", :with => user.email
      fill_in "password", :with => "test"
      click_on "Login", :match => :first
    end

    def xml_for_node(node)
      doc = OSM::API.new.get_xml_doc
      doc.root << xml_node_for_node(node)
      doc
    end

    def xml_node_for_node(node)
      el = XML::Node.new "node"
      el["id"] = node.id.to_s

      OMHelper.add_metadata_to_xml_node(el, node, {}, {})

      if node.visible?
        el["lat"] = node.lat.to_s
        el["lon"] = node.lon.to_s
      end

      OMHelper.add_tags_to_xml_node(el, node.node_tags)

      el
    end

    def xml_for_way(way)
      doc = OSM::API.new.get_xml_doc
      doc.root << xml_node_for_way(way)
      doc
    end

    def xml_node_for_way(way)
      el = XML::Node.new "way"
      el["id"] = way.id.to_s

      OMHelper.add_metadata_to_xml_node(el, way, {}, {})

      # make sure nodes are output in sequence_id order
      ordered_nodes = []
      way.way_nodes.each do |nd|
        ordered_nodes[nd.sequence_id] = nd.node_id.to_s if nd.node&.visible?
      end

      ordered_nodes.each do |nd_id|
        next unless nd_id && nd_id != "0"

        node_el = XML::Node.new "nd"
        node_el["ref"] = nd_id
        el << node_el
      end

      OMHelper.add_tags_to_xml_node(el, way.way_tags)

      el
    end

    def xml_for_relation(relation)
      doc = OSM::API.new.get_xml_doc
      doc.root << xml_node_for_relation(relation)
      doc
    end

    def xml_node_for_relation(relation)
      el = XML::Node.new "relation"
      el["id"] = relation.id.to_s

      OMHelper.add_metadata_to_xml_node(el, relation, {}, {})

      relation.relation_members.each do |member|
        member_el = XML::Node.new "member"
        member_el["type"] = member.member_type.downcase
        member_el["ref"] = member.member_id.to_s
        member_el["role"] = member.member_role
        el << member_el
      end

      OMHelper.add_tags_to_xml_node(el, relation.relation_tags)

      el
    end

    class OMHelper
      extend ObjectMetadata
    end
  end
end
