require "securerandom"
require "openssl"
require "base64"
require "digest/md5"

module PasswordHash
  SALT_BYTE_SIZE = 32
  HASH_BYTE_SIZE = 32
  PBKDF2_ITERATIONS = 1000
  DIGEST_ALGORITHM = "sha512"

  def self.create(password)
    salt = SecureRandom.base64(SALT_BYTE_SIZE)
    hash = self.hash(password, salt, PBKDF2_ITERATIONS, HASH_BYTE_SIZE, DIGEST_ALGORITHM)
    return hash, [DIGEST_ALGORITHM, PBKDF2_ITERATIONS, salt].join("!")
  end

  def self.check(hash, salt, candidate)
    if salt.nil?
      candidate = Digest::MD5.hexdigest(candidate)
    elsif salt =~ /!/
      algorithm, iterations, salt = salt.split("!")
      size = Base64.strict_decode64(hash).length
      candidate = self.hash(candidate, salt, iterations.to_i, size, algorithm)
    else
      candidate = Digest::MD5.hexdigest(salt + candidate)
    end

    return hash == candidate
  end

private

  def self.hash(password, salt, iterations, size, algorithm)
    digest = OpenSSL::Digest.new(algorithm)
    pbkdf2 = OpenSSL::PKCS5::pbkdf2_hmac(password, salt, iterations, size, digest)
    Base64.strict_encode64(pbkdf2)
  end
end
