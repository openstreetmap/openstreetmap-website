namespace :osm do
  namespace :apps do
    desc "Creates a client application"
    task :create do
      require File.dirname(__FILE__) + "/../../config/environment"

      unless ENV["name"] && ENV["url"]
        puts "Usage: rake osm:apps:create name='Local iD' url='http://localhost:3000'"
        exit 1
      end

      app = ClientApplication.find_or_create_by! \
        name: ENV["name"],
        url: ENV["url"],
        allow_write_api: true

      puts app.to_json
    end
  end
end
