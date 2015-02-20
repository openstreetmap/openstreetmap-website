# -*- coding: utf-8 -*-
require "test_helper"

class UTF8Test < ActiveSupport::TestCase
  def test_valid?
    assert_equal true, UTF8.valid?("test")
    assert_equal true, UTF8.valid?("vergrößern")
    assert_equal true, UTF8.valid?("ルシステムにも対応します")
    assert_equal true, UTF8.valid?("輕觸搖晃的遊戲")

    assert_equal false, UTF8.valid?("\xC0")         # always invalid utf8
    assert_equal false, UTF8.valid?("\xC2\x4a")     # 2-byte multibyte identifier, followed by plain ASCII
    assert_equal false, UTF8.valid?("\xC2\xC2")     # 2-byte multibyte identifier, followed by another one
    assert_equal false, UTF8.valid?("\x4a\x82")     # plain ASCII, followed by multibyte continuation
    assert_equal false, UTF8.valid?("\x82\x82")     # multibyte continuations without multibyte identifier
    assert_equal false, UTF8.valid?("\xe1\x82\x4a") # three-byte identifier, contination and (incorrectly) plain ASCII
  end
end
