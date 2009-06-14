$LOAD_PATH << File.join(File.dirname(__FILE__),"..","lib")
require 'lib/i18n_data'#TODO should not be necessary but is :/
require 'yaml'

desc "Run all specs in spec directory"
task :default do |t|
  options = "--colour --format progress --loadby --reverse"
  files = FileList['spec/**/*_spec.rb']
  system("spec #{options} #{files}")
end

desc "write all languages to output"
task :all_languages do
  I18nData.languages.keys.each do |lc|
    `rake languages LANGUAGE=#{lc}`
  end
end

desc "write languages to output/languages_{language}"
task :languages do
  raise unless language = ENV['LANGUAGE']
  `mkdir output -p`
  data = I18nData.languages(language.upcase)
  File.open("output/languages_#{language.downcase}.yml",'w') {|f|f.puts data.to_yaml}
end

desc "write all countries to output"
task :all_countries do
  I18nData.languages.keys.each do |lc|
    `rake countries LANGUAGE=#{lc}`
  end
end

desc "write countries to output/countries_{language}"
task :countries do
  raise unless language = ENV['LANGUAGE']
  `mkdir output -p`
  data = I18nData.countries(language.upcase)
  File.open("output/countries_#{language.downcase}.yml",'w') {|f|f.puts data.to_yaml}
end

desc "write example output, just to show off :D"
task :example_output do
  `mkdir example_output -p`
  
  #all names for germany, france, united kingdom and unites states
  ['DE','FR','GB','US'].each do |cc|
    names = I18nData.languages.keys.map do |lc|
      begin
        [I18nData.countries(lc)[cc], I18nData.languages[lc]]
      rescue I18nData::NoOnlineTranslationAvaiable
        nil
      end
    end
    File.open("example_output/all_names_for_#{cc}.txt",'w') {|f|
      f.puts names.reject(&:nil?).map{|x|x*" ---- "} * "\n"
    }
  end
end

desc "write cache for I18nData::FileDataProvider"
task :write_cache_for_file_data_provider do
  require 'i18n_data/file_data_provider'
  require 'i18n_data/live_data_provider'
  I18nData::FileDataProvider.write_cache(I18nData::LiveDataProvider)
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "i18n_data"
    gem.summary = "country/language names and 2-letter-code pairs, in 85 languages"
    gem.email = "grosser.michael@gmail.com"
    gem.homepage = "http://github.com/grosser/i18n_data"
    gem.authors = ["Michael Grosser"]
    gem.add_dependency ['activesupport']
    gem.files += (FileList["{lib,spec,cache}/**/*"] + FileList["VERSION.yml"] + FileList["README.markdown"]).to_a.sort
  end
rescue LoadError
  puts "Jeweler, or one of its dependencies, is not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end