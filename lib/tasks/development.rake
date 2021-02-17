if Rails.env.development?
  desc "Populate the development database with some fake data"
  namespace "dev" do
    task "populate" => :environment do
      # Ensure we generate the same data each time this is run
      Faker::Config.random = Random.new(42)

      # Ensure that all dates (e.g. terms_agreed) are consistent
      Timecop.freeze(Time.utc(2015, 10, 21, 12, 0, 0)) do
        _user = FactoryBot.find_or_create(:user, :display_name => Faker::Name.name)
      end
    end
  end
end
