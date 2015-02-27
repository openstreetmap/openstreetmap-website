require "test_helper"

class GeocoderHelperTest < ActionView::TestCase
  def test_result_to_html
    html = result_to_html(:lat => 1.23, :lon => 4.56, :zoom => 16, :name => "Name")
    assert_dom_equal %q(<a class="set_position" data-lat="1.23" data-lon="4.56" data-zoom="16" data-name="Name" href="/#map=16/1.23/4.56">Name</a>), html

    html = result_to_html(:lat => 1.23, :lon => 4.56, :zoom => 16, :prefix => "Prefix", :name => "Name")
    assert_dom_equal %q(Prefix <a class="set_position" data-lat="1.23" data-lon="4.56" data-zoom="16" data-prefix="Prefix" data-name="Name" href="/#map=16/1.23/4.56">Name</a>), html

    html = result_to_html(:lat => 1.23, :lon => 4.56, :zoom => 16, :name => "Name", :suffix => "Suffix")
    assert_dom_equal %q(<a class="set_position" data-lat="1.23" data-lon="4.56" data-zoom="16" data-name="Name" data-suffix="Suffix" href="/#map=16/1.23/4.56">Name</a> Suffix), html

    html = result_to_html(:lat => 1.23, :lon => 4.56, :zoom => 16, :prefix => "Prefix", :name => "Name", :suffix => "Suffix")
    assert_dom_equal %q(Prefix <a class="set_position" data-lat="1.23" data-lon="4.56" data-zoom="16" data-prefix="Prefix" data-name="Name" data-suffix="Suffix" href="/#map=16/1.23/4.56">Name</a> Suffix), html

    html = result_to_html(:type => "node", :id => 123456, :name => "Name")
    assert_dom_equal %q(<a class="set_position" data-type="node" data-id="123456" data-name="Name" href="/node/123456">Name</a>), html

    html = result_to_html(:min_lat => 1.23, :max_lat => 4.56, :min_lon => -1.23, :max_lon => 2.34, :name => "Name")
    assert_dom_equal %q(<a class="set_position" data-min-lat="1.23" data-max-lat="4.56" data-min-lon="-1.23" data-max-lon="2.34" data-name="Name" href="/?bbox=-1.23,1.23,2.34,4.56">Name</a), html
  end
end
