require 'test_helper'

class AssetHelperTest < ActionView::TestCase
  def test_assets
    assert assets("iD").kind_of?(Hash)
  end
end
