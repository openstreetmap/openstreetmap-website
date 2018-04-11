require "coveralls"
Coveralls.wear!("rails")

ENV["RAILS_ENV"] = "test"
require File.expand_path("../config/environment", __dir__)
require "rails/test_help"
require "webmock/minitest"

module ActiveSupport
  class TestCase
    include FactoryBot::Syntax::Methods

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
    # set the raw body to be sent with a POST request
    def content(c)
      @request.env["RAW_POST_DATA"] = c.to_s
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
      hash = Digest::MD5.hexdigest(email.downcase)
      url = "https://www.gravatar.com/avatar/#{hash}?d=404"
      stub_request(:get, url).and_return(:status => status, :body => body)
    end

    def stub_hostip_requests
      # Controller tests and integration tests use different IPs
      stub_request(:get, "http://api.hostip.info/country.php?ip=0.0.0.0")
      stub_request(:get, "http://api.hostip.info/country.php?ip=127.0.0.1")
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
      stub_hostip_requests
      visit login_path
      fill_in "username", :with => user.email
      fill_in "password", :with => "test"
      click_on "Login", :match => :first
    end
  end
end
