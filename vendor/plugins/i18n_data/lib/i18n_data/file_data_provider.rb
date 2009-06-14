module I18nData
  module FileDataProvider
    DATA_SEPERATOR = ";;"
    extend self

    def codes(type,language_code)
      unless data = read_from_file(type,language_code)
        raise NoTranslationAvailable.new("#{type}-#{language_code}")
      end
      data
    end

    def write_cache(provider)
      languages = provider.codes(:languages,'EN').keys
      languages.each{|language_code|
        [:languages,:countries].each {|type|
          begin
            data = provider.send(:codes,type,language_code)
            write_to_file(data,type,language_code)
          rescue NoTranslationAvailable
          end
        }
      }
    end

  private

    def read_from_file(type,language_code)
      file = cache_for(type,language_code)
      return nil unless File.exist?(file)
      data = {}
      IO.read(file).split("\n").each{|line|
        code, translation = line.split(DATA_SEPERATOR)
        data[code] = translation
      }
      data
    end

    def write_to_file(data,type,language_code)
      return if data.empty?
      file = cache_for(type,language_code)
      FileUtils.mkdir_p(File.dirname(file))
      File.open(file,'w') do |f|
        f.puts data.map{|code,translation|"#{code}#{DATA_SEPERATOR}#{translation}"} * "\n"
      end
    end

    def cache_for(type,language_code)
      cache("#{type}-#{language_code}")
    end

    def cache(file)
      File.join(File.dirname(__FILE__),'..','..','cache','file_data_provider',"#{file}.txt")
    end
  end
end