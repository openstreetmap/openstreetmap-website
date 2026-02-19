# frozen_string_literal: true

require "test_helper"

class SvgTransformsTest < ActionView::TestCase
  def test_asset_routing_transform
    context = Object.new
    context.extend(InlineSvg::ActionView::Helpers)

    svg = context.inline_svg_tag("social_link_icons/ohm.svg")
    assert_no_match "../osm_logo.svg", svg
    assert_match %r{assets/osm_logo-[0-9a-f]+.svg}, svg
  end
end
