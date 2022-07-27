require "argon2"
require "base64"
require "digest/md5"
require "openssl"
require "securerandom"

module PasswordHash
  FORMAT = Argon2::HashFormat.new(Argon2::Password.create(""))

  def self.create(password)
    hash = Argon2::Password.create(password)
    [hash, nil]
  end

  def self.check(hash, salt, candidate)
    if Argon2::HashFormat.valid_hash?(hash)
      Argon2::Password.verify_password(candidate, hash)
    elsif salt.nil?
      hash == Digest::MD5.hexdigest(candidate)
    elsif salt.include?("!")
      algorithm, iterations, salt = salt.split("!")
      size = Base64.strict_decode64(hash).length
      hash == pbkdf2(candidate, salt, iterations.to_i, size, algorithm)
    else
      hash == Digest::MD5.hexdigest(salt + candidate)
    end
  end

  def self.upgrade?(hash, _salt)
    format = Argon2::HashFormat.new(hash)

    format.variant != FORMAT.variant ||
      format.version != FORMAT.version ||
      format.t_cost != FORMAT.t_cost ||
      format.m_cost != FORMAT.m_cost ||
      format.p_cost != FORMAT.p_cost
  rescue Argon2::ArgonHashFail
    true
  end

  def self.pbkdf2(password, salt, iterations, size, algorithm)
    digest = OpenSSL::Digest.new(algorithm)
    pbkdf2 = OpenSSL::PKCS5.pbkdf2_hmac(password, salt, iterations, size, digest)
    Base64.strict_encode64(pbkdf2)
  end
end
