# frozen_string_literal: true

require "test_helper"

class ErrorsControllerTest < ActionDispatch::IntegrationTest
  def test_routes
    assert_routing(
      { :path => "/400", :method => :get },
      { :controller => "errors", :action => "bad_request" }
    )
    assert_routing(
      { :path => "/403", :method => :get },
      { :controller => "errors", :action => "forbidden" }
    )
    assert_routing(
      { :path => "/404", :method => :get },
      { :controller => "errors", :action => "not_found" }
    )
    assert_routing(
      { :path => "/500", :method => :get },
      { :controller => "errors", :action => "internal_server_error" }
    )
  end

  def test_bad_request
    get "/400"
    assert_response :bad_request
  end

  def test_forbidden
    get "/403"
    assert_response :forbidden
  end

  def test_not_found
    get "/404"
    assert_response :not_found
  end

  def test_internal_server_error
    get "/500"
    assert_response :internal_server_error
    assert_template "errors/internal_server_error"
  end

  ##
  # rails sets action_dispatch.original_path to the path of the request
  # that failed when it calls this controller to render the error
  def test_internal_server_error_api
    get "/500", :env => { "action_dispatch.original_path" => "/api/0.6/node/1" }
    assert_response :internal_server_error
    assert_equal "text/plain", @response.media_type
    assert_equal "Internal Server Error", @response.body
    assert_equal "Internal Server Error", @response.headers["Error"]
  end

  ##
  # errors requested with the X-Error-Format header are returned with a
  # 200 status, with the real status in the body
  def test_internal_server_error_api_error_format_xml
    get "/500", :headers => { "X-Error-Format" => "xml" }, :env => { "action_dispatch.original_path" => "/api/0.6/node/1" }
    assert_response :success
    assert_equal "application/xml", @response.media_type
    assert_dom "osmError > status", :text => /\A500\b/
    assert_dom "osmError > message", :text => "Internal Server Error"
  end
end
