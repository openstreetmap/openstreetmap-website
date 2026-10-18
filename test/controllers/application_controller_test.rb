# frozen_string_literal: true

require "test_helper"

class ApplicationControllerTest < ActiveSupport::TestCase
  def test_report_error_replaces_line_breaks_in_error_header
    assert_error_header "Bad input\r\nInjected-Header: value", "Bad input  Injected-Header: value"
  end

  def test_report_error_replaces_control_bytes_in_error_header
    assert_error_header "Bad\u0000\u0007\u007Finput", "Bad   input"
  end

  def test_report_error_keeps_tabs_in_error_header
    assert_error_header "Bad\tinput", "Bad\tinput"
  end

  private

  def assert_error_header(message, expected_header)
    headers = {}
    render_options = nil
    controller = ApplicationController.new
    response = Struct.new(:headers).new(headers)
    request = Struct.new(:headers).new({})

    controller.stub(:response, response) do
      controller.stub(:request, request) do
        controller.stub(:render, ->(options = nil, **keywords) { render_options = options || keywords }) do
          controller.send(:report_error, message)
        end
      end
    end

    assert_equal expected_header, headers["Error"]
    assert_equal({ :plain => message, :status => :bad_request }, render_options)
  end
end
