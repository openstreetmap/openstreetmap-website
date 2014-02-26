namespace :test do
  Rails::TestTask.new(lib: "test:prepare") do |t|    
    t.pattern = 'test/lib/**/*_test.rb'
  end
end
