require "test_helper"

class PasswordHashTest < ActiveSupport::TestCase
  def test_md5_without_salt
    assert PasswordHash.check("5f4dcc3b5aa765d61d8327deb882cf99", nil, "password")
    assert_not PasswordHash.check("5f4dcc3b5aa765d61d8327deb882cf99", nil, "wrong")
    assert PasswordHash.upgrade?("5f4dcc3b5aa765d61d8327deb882cf99", nil)
  end

  def test_md5_with_salt
    assert PasswordHash.check("67a1e09bb1f83f5007dc119c14d663aa", "salt", "password")
    assert_not PasswordHash.check("67a1e09bb1f83f5007dc119c14d663aa", "salt", "wrong")
    assert_not PasswordHash.check("67a1e09bb1f83f5007dc119c14d663aa", "wrong", "password")
    assert PasswordHash.upgrade?("67a1e09bb1f83f5007dc119c14d663aa", "salt")
  end

  def test_pbkdf2_1000_32_sha512
    assert PasswordHash.check("ApT/28+FsTBLa/J8paWfgU84SoRiTfeY8HjKWhgHy08=", "sha512!1000!HR4z+hAvKV2ra1gpbRybtoNzm/CNKe4cf7bPKwdUNrk=", "password")
    assert_not PasswordHash.check("ApT/28+FsTBLa/J8paWfgU84SoRiTfeY8HjKWhgHy08=", "sha512!1000!HR4z+hAvKV2ra1gpbRybtoNzm/CNKe4cf7bPKwdUNrk=", "wrong")
    assert_not PasswordHash.check("ApT/28+FsTBLa/J8paWfgU84SoRiTfeY8HjKWhgHy08=", "sha512!1000!HR4z+hAvKV2ra1gwrongtoNzm/CNKe4cf7bPKwdUNrk=", "password")
    assert PasswordHash.upgrade?("ApT/28+FsTBLa/J8paWfgU84SoRiTfeY8HjKWhgHy08=", "sha512!1000!HR4z+hAvKV2ra1gpbRybtoNzm/CNKe4cf7bPKwdUNrk=")
  end

  def test_pbkdf2_10000_32_sha512
    assert PasswordHash.check("3wYbPiOxk/tU0eeIDjUhdvi8aDP3AbFtwYKKxF1IhGg=", "sha512!10000!OUQLgtM7eD8huvanFT5/WtWaCwdOdrir8QOtFwxhO0A=", "password")
    assert_not PasswordHash.check("3wYbPiOxk/tU0eeIDjUhdvi8aDP3AbFtwYKKxF1IhGg=", "sha512!10000!OUQLgtM7eD8huvanFT5/WtWaCwdOdrir8QOtFwxhO0A=", "wrong")
    assert_not PasswordHash.check("3wYbPiOxk/tU0eeIDjUhdvi8aDP3AbFtwYKKxF1IhGg=", "sha512!10000!OUQLgtMwronguvanFT5/WtWaCwdOdrir8QOtFwxhO0A=", "password")
    assert PasswordHash.upgrade?("3wYbPiOxk/tU0eeIDjUhdvi8aDP3AbFtwYKKxF1IhGg=", "sha512!10000!OUQLgtM7eD8huvanFT5/WtWaCwdOdrir8QOtFwxhO0A=")
  end

  def test_argon2_upgradeable
    assert PasswordHash.check("$argon2id$v=19$m=65536,t=1,p=1$KXGHWfWMf5H5kY4uU3ua8A$YroVvX6cpJpljTio62k19C6UpuIPtW7me2sxyU2dyYg", nil, "password")
    assert_not PasswordHash.check("$argon2id$v=19$m=65536,t=1,p=1$KXGHWfWMf5H5kY4uU3ua8A$YroVvX6cpJpljTio62k19C6UpuIPtW7me2sxyU2dyYg", nil, "wrong")
    assert PasswordHash.upgrade?("$argon2id$v=19$m=65536,t=1,p=1$KXGHWfWMf5H5kY4uU3ua8A$YroVvX6cpJpljTio62k19C6UpuIPtW7me2sxyU2dyYg", nil)
  end

  def test_argon2
    assert PasswordHash.check("$argon2id$v=19$m=65536,t=2,p=1$b2E7zSvjT6TC5DXrqvfxwg$P4hly807ckgYc+kfvaf3rqmJcmKStzw+kV14oMaz8PQ", nil, "password")
    assert_not PasswordHash.check("$argon2id$v=19$m=65536,t=2,p=1$b2E7zSvjT6TC5DXrqvfxwg$P4hly807ckgYc+kfvaf3rqmJcmKStzw+kV14oMaz8PQ", nil, "wrong")
    assert_not PasswordHash.upgrade?("$argon2id$v=19$m=65536,t=2,p=1$b2E7zSvjT6TC5DXrqvfxwg$P4hly807ckgYc+kfvaf3rqmJcmKStzw+kV14oMaz8PQ", nil)
  end

  def test_default
    hash1, salt1 = PasswordHash.create("password")
    hash2, salt2 = PasswordHash.create("password")
    assert_not_equal hash1, hash2
    assert_nil salt1
    assert_nil salt2
    assert PasswordHash.check(hash1, salt1, "password")
    assert_not PasswordHash.check(hash1, salt1, "wrong")
    assert PasswordHash.check(hash2, salt2, "password")
    assert_not PasswordHash.check(hash2, salt2, "wrong")
    assert_not PasswordHash.upgrade?(hash1, salt1)
    assert_not PasswordHash.upgrade?(hash2, salt2)
  end

  def test_format
    hash, _salt = PasswordHash.create("password")
    format = Argon2::HashFormat.new(hash)

    assert_equal "argon2id", format.variant
    assert format.version <= 19
  end
end
