module Oauth
  SCOPES = %w[read_prefs write_prefs write_diary write_api read_gpx write_gpx write_notes].freeze
  PRIVILEGED_SCOPES = %w[read_email skip_authorization].freeze

  class Scope
    attr_reader :name

    def initialize(name)
      @name = name
    end

    def description
      I18n.t("oauth.scopes.#{name}")
    end
  end

  def self.scopes(privileged: false)
    scopes = SCOPES
    scopes += PRIVILEGED_SCOPES if privileged
    scopes.collect { |s| Scope.new(s) }
  end
end
