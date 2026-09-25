# frozen_string_literal: true

require "test_helper"

class OsmTest < ActiveSupport::TestCase
  def test_mercator
    proj = OSM::Mercator.new(0, 0, 1, 1, 100, 200)
    assert_in_delta(50, proj.x(0.5), 0.01)
    assert_in_delta(100, proj.y(0.5), 0.01)
  end

  def test_mercator_collapsed_bbox
    proj = OSM::Mercator.new(0, 0, 0, 0, 100, 200)
    assert_in_delta(50, proj.x(0), 0.01)
    assert_in_delta(100, proj.y(0), 0.01)
  end

  def test_legal_text_for_country
    OSM::LEGALES.each do |legale|
      text = OSM.legal_text_for_country(legale)

      assert_predicate text["intro"], :html_safe?
    end
  end

  def test_legal_text_for_unknown_country
    default_text = OSM.legal_text_for_country(Settings.default_legale)

    ["ZZ", "..", "../../config/settings", "/etc/passwd", "GB\n../../config/settings", nil]
      .each do |legale|
      assert_equal default_text, OSM.legal_text_for_country(legale)
    end
  end
end
