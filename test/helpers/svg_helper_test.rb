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
    svg = key_svg_tag("width" => 80, "height" => 20, "line" => "blue")
    expected = <<~HTML.gsub(/\n\s*/, "")
      <svg width="80" height="20">
        <line x2="100%" y1="50%" y2="50%" stroke="blue" />
      </svg>
    HTML
    assert_dom_equal expected, svg
  end

  def test_key_line_width
    svg = key_svg_tag("width" => 80, "height" => 20, "line" => "blue", "line-width" => 3)
    expected = <<~HTML.gsub(/\n\s*/, "")
      <svg width="80" height="20">
        <line x2="100%" y1="50%" y2="50%" stroke="blue" stroke-width="3" />
      </svg>
    HTML
    assert_dom_equal expected, svg
  end

  def test_key_casing
    svg = key_svg_tag("width" => 80, "height" => 20, "casing" => "yellow")
    expected = <<~HTML.gsub(/\n\s*/, "")
      <svg width="80" height="20">
        <g stroke="yellow">
          <line x2="100%" y1="0.5" y2="0.5" />
          <line x2="100%" y1="19.5" y2="19.5" />
        </g>
      </svg>
    HTML
    assert_dom_equal expected, svg
  end

  def test_key_casing_width
    svg = key_svg_tag("width" => 80, "height" => 20, "casing" => "yellow", "casing-width" => 5)
    expected = <<~HTML.gsub(/\n\s*/, "")
      <svg width="80" height="20">
        <g stroke="yellow" stroke-width="5">
          <line x2="100%" y1="2.5" y2="2.5" />
          <line x2="100%" y1="17.5" y2="17.5" />
        </g>
      </svg>
    HTML
    assert_dom_equal expected, svg
  end
end
