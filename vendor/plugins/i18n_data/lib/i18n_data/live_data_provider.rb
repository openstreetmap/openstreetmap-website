require 'open-uri'
require 'rexml/document'
gem 'activesupport', '> 2.2'
require 'activesupport'

module I18nData
  # fetches data online from debian svn
  module LiveDataProvider
    extend ActiveSupport::Memoizable
    extend self
    
    XML_CODES = {
      :countries => 'http://svn.debian.org/viewsvn/*checkout*/pkg-isocodes/trunk/iso-codes/iso_3166/iso_3166.xml',
      :languages => 'http://svn.debian.org/viewsvn/*checkout*/pkg-isocodes/trunk/iso-codes/iso_639/iso_639.xml'
    }
    TRANSLATIONS = {
      :languages => 'http://svn.debian.org/viewsvn/*checkout*/pkg-isocodes/trunk/iso-codes/iso_639/',
      :countries => 'http://svn.debian.org/viewsvn/*checkout*/pkg-isocodes/trunk/iso-codes/iso_3166/'
    }

    def codes(type,language_code)
      language_code = language_code.upcase
      if language_code == 'EN'
        send("english_#{type}")
      else
        translated(type,language_code)
      end
    end

  private

    def translate(type,language,to_language_code)
      translated = translations(type,to_language_code)[language]
      translated.to_s.empty? ? nil : translated
    end

    def translated(type,language_code)
      translations = {}
      send("english_#{type}").each do |code,name|
        translation = translate(type,name,language_code)
        translations[code] = translation ? translation : name
      end
      translations
    end
    memoize :translated

    def translations(type,language_code)
      begin
        data = open(TRANSLATIONS[type]+"#{language_code.downcase}.po").readlines
      rescue
        raise NoTranslationAvailable.new("for #{type} and language code = #{language_code}")
      end

      po_to_hash(data)
    end
    memoize :translations

    def english_languages
      codes = {}
      xml(:languages).elements.each('*/iso_639_entry') do |entry|
        name = entry.attributes['name'].to_s.gsub("'","\\'")
        code = entry.attributes['iso_639_1_code'].to_s.upcase
        next if code.empty? or name.empty?
        codes[code]=name
      end
      codes
    end
    memoize :english_languages

    def english_countries
      codes = {}
      xml(:countries).elements.each('*/iso_3166_entry') do |entry|
        name = entry.attributes['name'].to_s.gsub("'","\\'")
        code = entry.attributes['alpha_2_code'].to_s.upcase
        codes[code]=name
      end
      codes
    end
    memoize :english_countries

    def po_to_hash(data)
      names = data.select{|l| l =~ /^msgid/}.map{|line| line.match(/^msgid "(.*?)"/)[1]}
      translations = data.select{|l| l =~ /^msgstr/}.map{|line| line.match(/^msgstr "(.*?)"/)[1]}

      translated = {}
      names.each_with_index do |name,index|
        translated[name]=translations[index]
      end
      translated
    end

    def xml(type)
      xml = open(XML_CODES[type]).read
      REXML::Document.new(xml)
    end
  end
end