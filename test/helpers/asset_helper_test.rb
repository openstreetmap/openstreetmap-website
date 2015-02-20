require "test_helper"

class AssetHelperTest < ActionView::TestCase
  def test_assets
    assert assets("iD").is_a?(Hash)
  end
end
