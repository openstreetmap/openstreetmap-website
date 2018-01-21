FactoryBot.define do
  factory :changeset_comment do
    sequence(:body) { |n| "Changeset comment #{n}" }
    visible true

    changeset

    association :author, :factory => :user
  end
end
