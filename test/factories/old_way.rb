FactoryBot.define do
  factory :old_way do
    timestamp { Time.now.utc }
    visible { true }
    version { 1 }

    changeset
    current_way :factory => :way
  end
end
