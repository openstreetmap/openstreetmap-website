module Oauth
  SCOPES = %w[read_prefs write_prefs write_diary write_api read_gpx write_gpx write_notes].freeze

  class Scope
    attr_reader :name

    def initialize(name)
      @name = name
    end

    def description
      I18n.t("oauth.scopes.#{name}")
    end
  end

  def self.scopes
    SCOPES.collect { |s| Scope.new(s) }
  end
end
