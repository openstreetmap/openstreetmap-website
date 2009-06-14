require 'activesupport'
module I18nData
  extend self
  
  def languages(language_code='EN')
    data_provider.codes(:languages,language_code.to_s.upcase)
  end

  def countries(language_code='EN')
    data_provider.codes(:countries,language_code.to_s.upcase)
  end

  def data_provider
    if @data_provider
      @data_provider
    else
      require 'i18n_data/file_data_provider'
      FileDataProvider
    end
  end

  def data_provider=(provider)
    @data_provider = provider
  end
  
  class NoTranslationAvailable < Exception
    def to_s
      "NoTranslationAvailable -- #{super}"
    end
  end
end