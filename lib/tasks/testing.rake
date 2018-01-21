task "test" do
  Rails::TestUnit::Runner.rake_run(["test/system"]) unless ENV.key?("TEST")
end

namespace :test do
  task "lib" => "test:prepare" do
    $LOAD_PATH << "test"
    Rails::TestUnit::Runner.rake_run(["test/lib"])
  end
end
