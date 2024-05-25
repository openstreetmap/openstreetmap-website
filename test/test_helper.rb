require "simplecov"
require "simplecov-lcov"

# Fix incompatibility of simplecov-lcov with older versions of simplecov that are not expresses in its gemspec.
# https://github.com/fortissimo1997/simplecov-lcov/pull/25
unless SimpleCov.respond_to?(:branch_coverage)
  module SimpleCov
    def self.branch_coverage?
      false
    end
  end
end

SimpleCov::Formatter::LcovFormatter.config do |config|
  config.report_with_single_file = true
  config.single_report_path = "coverage/lcov.info"
end

SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new(
  [
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::LcovFormatter
  ]
)

SimpleCov.start("rails")

require "securerandom"
require "digest/sha1"

ENV["RAILS_ENV"] = "test"
require_relative "../config/environment"
require "rails/test_help"
require "webmock/minitest"
require "minitest/focus" unless ENV["CI"]

WebMock.disable_net_connect!(:allow_localhost => true)

module ActiveSupport
  class TestCase
    include FactoryBot::Syntax::Methods
    include ActiveJob::TestHelper

    # Run tests in parallel with specified workers
    parallelize(:workers => :number_of_processors)

    parallelize_setup do |worker|
      SimpleCov.command_name "#{SimpleCov.command_name}-#{worker}"
    end

    parallelize_teardown do
      SimpleCov.result
    end

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
    # return request header for HTTP Basic Authorization
    def basic_authorization_header(user, pass)
      { "Authorization" => format("Basic %<auth>s", :auth => Base64.encode64("#{user}:#{pass}")) }
    end

    ##
    # return request header for HTTP Bearer Authorization
    def bearer_authorization_header(token)
      { "Authorization" => "Bearer #{token}" }
    end

    ##
    # make an OAuth signed request
    def signed_request(method, uri, options = {})
      uri = URI.parse(uri)
      uri.scheme ||= "http"
      uri.host ||= "www.example.com"

      oauth = options.delete(:oauth)
      params = options.fetch(:params, {}).transform_keys(&:to_s)

      oauth[:consumer] ||= oauth[:token].client_application

      helper = OAuth::Client::Helper.new(nil, oauth)

      request = OAuth::RequestProxy.proxy(
        "method" => method.to_s.upcase,
        "uri" => uri,
        "parameters" => params.merge(helper.oauth_parameters)
      )

      request.sign!(oauth)

      method(method).call(request.signed_uri, **options)
    end

    ##
    # make an OAuth signed GET request
    def signed_get(uri, options = {})
      signed_request(:get, uri, options)
    end

    ##
    # make an OAuth signed POST request
    def signed_post(uri, options = {})
      signed_request(:post, uri, options)
    end

    ##
    # return request header for HTTP Accept
    def accept_format_header(format)
      { "Accept" => format }
    end

    ##
    # return request header to ask for a particular error format
    def error_format_header(f)
      { "X-Error-Format" => f }
    end

    ##
    # Used to check that the error header and the forbidden responses are given
    # when the owner of the changeset has their data not marked as public
    def assert_require_public_data(msg = "Shouldn't be able to use API when the user's data is not public")
      assert_response :forbidden, msg
      assert_equal("You must make your edits public to upload new data", @response.headers["Error"], "Wrong error message")
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

    def session_for(user)
      get login_path
      post login_path, :params => { :username => user.display_name, :password => "test" }
      follow_redirect!
    end

    def xml_for_node(node)
      doc = OSM::API.new.xml_doc
      doc.root << xml_node_for_node(node)
      doc
    end

    def xml_node_for_node(node)
      el = XML::Node.new "node"
      el["id"] = node.id.to_s

      add_metadata_to_xml_node(el, node, {}, {})

      if node.visible?
        el["lat"] = node.lat.to_s
        el["lon"] = node.lon.to_s
      end

      add_tags_to_xml_node(el, node.node_tags)

      el
    end

    def xml_for_way(way)
      doc = OSM::API.new.xml_doc
      doc.root << xml_node_for_way(way)
      doc
    end

    def xml_node_for_way(way)
      el = XML::Node.new "way"
      el["id"] = way.id.to_s

      add_metadata_to_xml_node(el, way, {}, {})

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

      add_tags_to_xml_node(el, way.way_tags)

      el
    end

    def xml_for_relation(relation)
      doc = OSM::API.new.xml_doc
      doc.root << xml_node_for_relation(relation)
      doc
    end

    def xml_node_for_relation(relation)
      el = XML::Node.new "relation"
      el["id"] = relation.id.to_s

      add_metadata_to_xml_node(el, relation, {}, {})

      relation.relation_members.each do |member|
        member_el = XML::Node.new "member"
        member_el["type"] = member.member_type.downcase
        member_el["ref"] = member.member_id.to_s
        member_el["role"] = member.member_role
        el << member_el
      end

      add_tags_to_xml_node(el, relation.relation_tags)

      el
    end

    def validate(attrs, result)
      object_class = self.class.name.dup.sub!(/Test$/, "").underscore
      object = build(object_class, attrs)
      valid = object.valid?
      errors = object.errors.messages
      assert_equal result, valid, "Expected #{attrs.inspect} to be #{result} but #{errors}"
    end

    def add_metadata_to_xml_node(el, osm, changeset_cache, user_display_name_cache)
      el["changeset"] = osm.changeset_id.to_s
      el["redacted"] = osm.redaction.id.to_s if osm.redacted?
      el["timestamp"] = osm.timestamp.xmlschema
      el["version"] = osm.version.to_s
      el["visible"] = osm.visible.to_s

      if changeset_cache.key?(osm.changeset_id)
        # use the cache if available
      else
        changeset_cache[osm.changeset_id] = osm.changeset.user_id
      end

      user_id = changeset_cache[osm.changeset_id]

      if user_display_name_cache.key?(user_id)
        # use the cache if available
      elsif osm.changeset.user.data_public?
        user_display_name_cache[user_id] = osm.changeset.user.display_name
      else
        user_display_name_cache[user_id] = nil
      end

      unless user_display_name_cache[user_id].nil?
        el["user"] = user_display_name_cache[user_id]
        el["uid"] = user_id.to_s
      end
    end

    def add_tags_to_xml_node(el, tags)
      tags.each do |tag|
        tag_el = XML::Node.new("tag")

        tag_el["k"] = tag.k
        tag_el["v"] = tag.v

        el << tag_el
      end
    end

    def with_settings(settings)
      saved_settings = Settings.to_hash.slice(*settings.keys)

      Settings.merge!(settings)

      yield
    ensure
      Settings.merge!(saved_settings)
    end

    def with_user_account_deletion_delay(value, &block)
      freeze_time

      with_settings(:user_account_deletion_delay => value, &block)
    ensure
      unfreeze_time
    end

    # This is a convenience method for checks of resources rendered in a map view sidebar
    # First we check that when we don't have an id, it will correctly return a 404
    # then we check that we get the correct 404 when a non-existant id is passed
    # then we check that it will get a successful response, when we do pass an id
    def sidebar_browse_check(path, id, template)
      path_method = method(path)

      assert_raise ActionController::UrlGenerationError do
        get path_method.call
      end

      assert_raise ActionController::UrlGenerationError do
        get path_method.call(:id => -10) # we won't have an id that's negative
      end

      get path_method.call(:id => 0)
      assert_response :not_found
      assert_template "browse/not_found"
      assert_template :layout => "map"

      get path_method.call(:id => 0), :xhr => true
      assert_response :not_found
      assert_template "browse/not_found"
      assert_template :layout => "xhr"

      get path_method.call(:id => id)
      assert_response :success
      assert_template template
      assert_template :layout => "map"

      get path_method.call(:id => id), :xhr => true
      assert_response :success
      assert_template template
      assert_template :layout => "xhr"
    end
  end
end
