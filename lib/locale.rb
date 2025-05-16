class Locale < I18n::Locale::Tag::Rfc4646
  class List < Array
    attr_reader :locales

    def initialize(tags)
      super(tags.map { |tag| Locale.tag(tag) }).compact!
    end

    def candidates(preferred)
      preferred.expand & self
    end

    def preferred(preferred, options = { :default => Locale.default })
      candidates(preferred).first || options[:default]
    end

    def expand
      List.new(reverse.each_with_object([]) do |locale, expanded|
                 locale.candidates.uniq.reverse_each do |candidate|
                   expanded << candidate if candidate == locale || expanded.exclude?(candidate)
                 end
               end.reverse.uniq)
    end
  end

  def self.list(*tags)
    List.new(tags.flatten)
  end

  def self.default
    tag(I18n.default_locale)
  end

  def self.available
    @available ||= List.new(I18n.available_locales).reject!(&:invalid?)
  end

  def invalid?
    !I18n.exists? "activerecord.models.acl", :locale => self, :fallback => false
  end

  def candidates
    List.new([self.class.new(language, script, region, variant),
              self.class.new(language, script, region),
              self.class.new(language, script, nil, variant),
              self.class.new(language, script),
              self.class.new(language, nil, region, variant),
              self.class.new(language, nil, region),
              self.class.new(language, nil, nil, variant),
              self.class.new(language)])
  end
end
