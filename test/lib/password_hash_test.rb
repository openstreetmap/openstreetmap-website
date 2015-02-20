require "test_helper"

class PasswordHashTest < ActiveSupport::TestCase
  def test_md5_without_salt
    assert_equal true, PasswordHash.check("5f4dcc3b5aa765d61d8327deb882cf99", nil, "password")
    assert_equal false, PasswordHash.check("5f4dcc3b5aa765d61d8327deb882cf99", nil, "wrong")
    assert_equal true, PasswordHash.upgrade?("5f4dcc3b5aa765d61d8327deb882cf99", nil)
  end

  def test_md5_with_salt
    assert_equal true, PasswordHash.check("67a1e09bb1f83f5007dc119c14d663aa", "salt", "password")
    assert_equal false, PasswordHash.check("67a1e09bb1f83f5007dc119c14d663aa", "salt", "wrong")
    assert_equal false, PasswordHash.check("67a1e09bb1f83f5007dc119c14d663aa", "wrong", "password")
    assert_equal true, PasswordHash.upgrade?("67a1e09bb1f83f5007dc119c14d663aa", "salt")
  end

  def test_default
    hash1, salt1 = PasswordHash.create("password")
    hash2, salt2 = PasswordHash.create("password")
    assert_not_equal hash1, hash2
    assert_not_equal salt1, salt2
    assert_equal true, PasswordHash.check(hash1, salt1, "password")
    assert_equal false, PasswordHash.check(hash1, salt1, "wrong")
    assert_equal true, PasswordHash.check(hash2, salt2, "password")
    assert_equal false, PasswordHash.check(hash2, salt2, "wrong")
    assert_equal false, PasswordHash.upgrade?(hash1, salt1)
    assert_equal false, PasswordHash.upgrade?(hash2, salt2)
  end
end
