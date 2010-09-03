spec = Gem::Specification.new do |s|
  s.name = 'validates_email_format_of'
  s.version = '1.4.1'
  s.summary = 'Validate e-mail addresses against RFC 2822 and RFC 3696.'
  s.description = s.summary
  s.extra_rdoc_files = ['README.rdoc', 'CHANGELOG.rdoc', 'MIT-LICENSE']
  s.test_files = ['test/validates_email_format_of_test.rb','test/test_helper.rb','test/schema.rb','test/fixtures/person.rb', 'test/fixtures/people.yml']
  s.files = ['init.rb','rakefile.rb', 'lib/validates_email_format_of.rb','rails/init.rb']
  s.files << s.test_files
  s.files << s.extra_rdoc_files
  s.require_path = 'lib'
  s.has_rdoc = true
  s.rdoc_options << '--title' <<  'validates_email_format_of'
  s.author = "Alex Dunae"
  s.email = "code@dunae.ca"
  s.homepage = "http://code.dunae.ca/validates_email_format_of.html"
end

