require 'rake'
require 'rake/testtask'

desc "Default task"
task :default => [ :test ]

Rake::TestTask.new do |t|
  t.test_files = Dir["test/**/*_test.rb"]
  t.verbose = true
end
