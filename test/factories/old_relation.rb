FactoryBot.define do
  factory :old_relation do
    timestamp { Time.now }
    visible { true }
    version { 1 }

    changeset
    association :current_relation, :factory => :relation
  end
end
