class Locale < I18n::Locale::Tag::Rfc4646
  class List < Array
    attr_reader :locales

    def initialize(tags)
      super(tags.map { |tag| Locale.tag(tag) })
    end

    def candidates(preferred)
      preferred.expand & self
    end

    def preferred(preferred)
      candidates(preferred).first
    end

    def expand
      map(&:candidates).flatten.uniq << Locale.default
    end
  end

  def self.list(*tags)
    List.new(tags.flatten)
  end

  def self.default
    tag(I18n.default_locale)
  end

  def self.available
    @available ||= List.new(I18n.available_locales)
  end

  def candidates
    [self.class.new(language, script, region, variant),
     self.class.new(language, script, region),
     self.class.new(language, script, nil, variant),
     self.class.new(language, script),
     self.class.new(language, nil, region, variant),
     self.class.new(language, nil, region),
     self.class.new(language, nil, nil, variant),
     self.class.new(language)]
  end
end
