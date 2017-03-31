FactoryGirl.define do
  factory :changeset do
    created_at Time.now.utc
    closed_at Time.now.utc + 1.day

    user
  end
end
