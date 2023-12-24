require "test_helper"

class SvgHelperTest < ActionView::TestCase
  def test_key_fill
    svg = key_svg_tag("width" => 60, "height" => 40, "fill" => "green")
    expected = <<~HTML.gsub(/\n\s*/, "")
      <svg width="60" height="40">
        <rect width="100%" height="100%" fill="green" />
      </svg>
    HTML
    assert_dom_equal expected, svg
  end

  def test_key_border
    svg = key_svg_tag("width" => 60, "height" => 40, "border" => "red")
    expected = <<~HTML.gsub(/\n\s*/, "")
      <svg width="60" height="40">
        <rect x="0.5" y="0.5" width="59" height="39" fill="none" stroke="red" />
      </svg>
    HTML
    assert_dom_equal expected, svg
  end

  def test_key_border_width
    svg = key_svg_tag("width" => 60, "height" => 40, "border" => "red", "border-width" => 3)
    expected = <<~HTML.gsub(/\n\s*/, "")
      <svg width="60" height="40">
        <rect x="1.5" y="1.5" width="57" height="37" fill="none" stroke="red" stroke-width="3" />
      </svg>
    HTML
    assert_dom_equal expected, svg
  end

  def test_key_border_with_integer_coords
    svg = key_svg_tag("width" => 60, "height" => 40, "border" => "red", "border-width" => 2)
    expected = <<~HTML.gsub(/\n\s*/, "")
      <svg width="60" height="40">
        <rect x="1" y="1" width="58" height="38" fill="none" stroke="red" stroke-width="2" />
      </svg>
    HTML
    assert_dom_equal expected, svg
  end

  def test_key_border_fractional_width
    svg = key_svg_tag("width" => 60, "height" => 40, "border" => "red", "border-width" => 1.5)
    expected = <<~HTML.gsub(/\n\s*/, "")
      <svg width="60" height="40">
        <rect x="0.75" y="0.75" width="58.5" height="38.5" fill="none" stroke="red" stroke-width="1.5" />
      </svg>
    HTML
    assert_dom_equal expected, svg
  end

  def test_key_line
    svg = key_svg_tag("width" => 80, "height" => 15, "line" => "blue")
    expected = <<~HTML.gsub(/\n\s*/, "")
      <svg width="80" height="15">
        <path d="M0,7.5 H80" stroke="blue" />
      </svg>
    HTML
    assert_dom_equal expected, svg
  end

  def test_key_line_width
    svg = key_svg_tag("width" => 80, "height" => 15, "line" => "blue", "line-width" => 3)
    expected = <<~HTML.gsub(/\n\s*/, "")
      <svg width="80" height="15">
        <path d="M0,7.5 H80" stroke="blue" stroke-width="3" />
      </svg>
    HTML
    assert_dom_equal expected, svg
  end

  def test_key_line_with_integer_coords
    svg = key_svg_tag("width" => 80, "height" => 20, "line" => "blue")
    expected = <<~HTML.gsub(/\n\s*/, "")
      <svg width="80" height="20">
        <path d="M0,10 H80" stroke="blue" />
      </svg>
    HTML
    assert_dom_equal expected, svg
  end

  def test_key_casing
    svg = key_svg_tag("width" => 80, "height" => 20, "casing" => "yellow")
    expected = <<~HTML.gsub(/\n\s*/, "")
      <svg width="80" height="20">
        <path d="M0,0.5 H80 M0,19.5 H80" stroke="yellow" />
      </svg>
    HTML
    assert_dom_equal expected, svg
  end

  def test_key_casing_width
    svg = key_svg_tag("width" => 80, "height" => 20, "casing" => "yellow", "casing-width" => 5)
    expected = <<~HTML.gsub(/\n\s*/, "")
      <svg width="80" height="20">
        <path d="M0,2.5 H80 M0,17.5 H80" stroke="yellow" stroke-width="5" />
      </svg>
    HTML
    assert_dom_equal expected, svg
  end

  def test_key_casing_with_integer_coords
    svg = key_svg_tag("width" => 80, "height" => 20, "casing" => "yellow", "casing-width" => 2)
    expected = <<~HTML.gsub(/\n\s*/, "")
      <svg width="80" height="20">
        <path d="M0,1 H80 M0,19 H80" stroke="yellow" stroke-width="2" />
      </svg>
    HTML
    assert_dom_equal expected, svg
  end
end
