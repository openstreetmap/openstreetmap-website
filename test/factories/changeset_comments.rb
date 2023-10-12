FactoryBot.define do
  factory :changeset_comment do
    sequence(:body) { |n| "Changeset comment #{n}" }
    visible { true }

    changeset

    author :factory => :user
  end
end
