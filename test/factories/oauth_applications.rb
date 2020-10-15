FactoryBot.define do
  factory :oauth_application, :class => "Doorkeeper::Application" do
    sequence(:name) { |n| "OAuth application #{n}" }
    sequence(:redirect_uri) { |n| "https://example.com/app/#{n}" }

    association :owner, :factory => :user
  end
end
