FactoryGirl.define do
  factory :way do
    timestamp Time.now
    visible true
    version 1

    changeset

    trait :deleted do
      visible false
    end

    trait :with_history do
      after(:create) do |way, _evaluator|
        (1..way.version).each do |n|
          create(:old_way, :way_id => way.id, :version => n, :changeset => way.changeset)
        end

        # For deleted ways, make sure the most recent old_way is also deleted.
        if way.visible == false
          latest = way.old_ways.find_by(:version => way.version)
          latest.visible = false
          latest.save
        end
      end
    end

    factory :way_with_nodes do
      transient do
        nodes_count 1
      end

      after(:create) do |way, evaluator|
        (1..evaluator.nodes_count).each do |n|
          create(:way_node, :way => way, :sequence_id => n)
        end
      end
    end
  end
end
