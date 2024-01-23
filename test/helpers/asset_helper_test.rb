require "test_helper"

class AssetHelperTest < ActionView::TestCase
  def test_assets
    assert_kind_of Hash, assets("iD")
  end
end
