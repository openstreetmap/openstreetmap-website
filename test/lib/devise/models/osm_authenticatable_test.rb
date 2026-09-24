# frozen_string_literal: true

require "test_helper"

module Devise
  module Models
    class OsmAuthenticatableTest < ActiveSupport::TestCase
      class Model
        def self.after_update(*)
        end

        include Devise::Models::OsmAuthenticatable

        def initialize(encrypted_password:, salt:)
          @encrypted_password = encrypted_password
          @salt = salt
          @saved = false
        end

        attr_accessor :encrypted_password, :salt

        def save
          @saved = true
        end

        def saved?
          @saved
        end
      end

      def functions
        Devise::Models::OsmAuthenticatable::Functions
      end

      def test_md5_without_salt
        model = Model.new(
          # Digest::MD5.hexdigest("password")
          encrypted_password: "5f4dcc3b5aa765d61d8327deb882cf99",
          salt: nil
        )
        assert_not model.valid_password?("password")

        # No upgrade
        assert_equal "5f4dcc3b5aa765d61d8327deb882cf99", model.encrypted_password
        assert_not model.saved?
      end

      def test_md5_with_salt
        model = Model.new(
          # Digest::MD5.hexdigest("saltpassword")
          encrypted_password: "67a1e09bb1f83f5007dc119c14d663aa",
          salt: "salt",
        )
        assert_not model.valid_password?("password")

        # No upgrade
        assert_equal "67a1e09bb1f83f5007dc119c14d663aa", model.encrypted_password
        assert_not model.saved?
      end

      def test_pbkdf2_1000_32_sha512
        initial_encrypted_password = "ApT/28+FsTBLa/J8paWfgU84SoRiTfeY8HjKWhgHy08="
        model = Model.new(
          encrypted_password: initial_encrypted_password,
          salt: "sha512!1000!HR4z+hAvKV2ra1gpbRybtoNzm/CNKe4cf7bPKwdUNrk=",
        )
        assert functions.needs_upgrade?(model.encrypted_password)

        assert_not model.valid_password?("bad password")
        assert_not model.saved?

        assert model.valid_password?("password")
        assert model.saved?

        assert_not_equal initial_encrypted_password, model.encrypted_password
        assert_nil model.salt
        assert_not functions.needs_upgrade?(model.encrypted_password)
      end

      def test_pbkdf2_10000_32_sha512
        initial_encrypted_password = "3wYbPiOxk/tU0eeIDjUhdvi8aDP3AbFtwYKKxF1IhGg="
        model = Model.new(
          encrypted_password: initial_encrypted_password,
          salt: "sha512!10000!OUQLgtM7eD8huvanFT5/WtWaCwdOdrir8QOtFwxhO0A="
        )
        assert functions.needs_upgrade?(model.encrypted_password)

        assert_not model.valid_password?("bad password")
        assert_not model.saved?

        assert model.valid_password?("password")
        assert model.saved?

        assert_not_equal initial_encrypted_password, model.encrypted_password
        assert_nil model.salt
        assert_not functions.needs_upgrade?(model.encrypted_password)
      end

      def test_argon2_t2_m16_p1
        initial_encrypted_password = "$argon2id$v=19$m=65536,t=2,p=1$b2E7zSvjT6TC5DXrqvfxwg$P4hly807ckgYc+kfvaf3rqmJcmKStzw+kV14oMaz8PQ"
        model = Model.new(
          encrypted_password: initial_encrypted_password,
          salt: nil
        )
        assert functions.needs_upgrade?(model.encrypted_password)

        assert_not model.valid_password?("bad password")
        assert_not model.saved?

        assert model.valid_password?("password")
        assert model.saved?

        assert_not_equal initial_encrypted_password, model.encrypted_password
        assert_nil model.salt
        assert_not functions.needs_upgrade?(model.encrypted_password)
      end

      def test_argon2_t3_m16_p4
        initial_encrypted_password = "$argon2id$v=19$m=65536,t=3,p=4$uxzL4aYTEDTRr2+KNA1qNQ$yuNOtH+IsCwWUbE4OGu+hIC0e4iyZ2wGhaCsQY1mJpI"
        model = Model.new(
          encrypted_password: initial_encrypted_password,
          salt: nil
        )
        assert_not functions.needs_upgrade?(model.encrypted_password)

        assert_not model.valid_password?("bad password")
        assert_not model.saved?

        assert model.valid_password?("password")
        assert_not model.saved?

        assert_equal initial_encrypted_password, model.encrypted_password
        assert_nil model.salt
        assert_not functions.needs_upgrade?(model.encrypted_password)
      end
    end
  end
end
