# A backend for FrozenRecord

module OsmCommunityIndex
  module ResourceBackend
    def self.filename(_model)
      "resources.json"
    end

    def self.load(file_path)
      resources = JSON.parse(File.read(file_path))
      resources["resources"].values.map! do |v|
        v["strings"]["url"] = nil unless valid_url? v["strings"]["url"]
      end
      resources["resources"].values
    end

    # This is to avoid any problems if upstream contains urls with `script:` or
    # similar schemes, i.e. to guard against supply-chain attacks.
    # Unfortunately the validates_url gem doesn't support `mailto:` or similar
    # urls. This method is based on their approach to validation.
    def self.valid_url?(url)
      return true if url.nil?

      schemes = %w[http https mailto xmpp]
      uri = URI.parse(url)
      scheme = uri&.scheme

      valid_raw_url = scheme && url =~ /\A#{URI::DEFAULT_PARSER.make_regexp([scheme])}\z/
      valid_scheme = scheme && schemes.include?(scheme)
      return true if valid_raw_url && valid_scheme

      false
    rescue URI::InvalidURIError, URI::InvalidComponentError
      false
    end
  end
end
