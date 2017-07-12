namespace :test do
  task "lib" => "test:prepare" do
    $LOAD_PATH << "test"
    Minitest.rake_run(["test/lib"])
  end
end
