FactoryGirl.define do
  factory :relation do
    timestamp Time.now
    visible true
    version 1

    changeset

    trait :deleted do
      visible false
    end

    trait :with_history do
      after(:create) do |relation, _evaluator|
        (1..relation.version).each do |n|
          create(:old_relation, :relation_id => relation.id, :version => n, :changeset => relation.changeset)
        end

        # For deleted relations, make sure the most recent old_relation is also deleted.
        if relation.visible == false
          latest = relation.old_relations.find_by(:version => relation.version)
          latest.visible = false
          latest.save
        end
      end
    end
  end
end
