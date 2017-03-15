FactoryGirl.define do
  factory :client_application do
    sequence(:name) { |n| "Client application #{n}" }
    sequence(:url) { |n| "http://example.com/app/#{n}" }

    user
  end
end
