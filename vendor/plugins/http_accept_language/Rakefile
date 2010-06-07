require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "http_accept_language"
    gem.summary = %Q{Parse the HTTP Accept Language Header}
    gem.description = %Q{Find out which locale the user preferes by reading the languages they specified in their browser}
    gem.email = "iain@iain.nl"
    gem.homepage = "http://github.com/iain/http_accept_language"
    gem.authors = ["Iain Hecker"]
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

require 'rake/testtask'
desc 'Test the http_accept_language plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Default: run unit tests.'
task :default => :test

require 'rake/rdoctask'
desc 'Generate documentation for the http_accept_language plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'HttpAcceptLanguage'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
