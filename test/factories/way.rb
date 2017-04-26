FactoryGirl.define do
  factory :way do
    timestamp Time.now
    visible true
    version 1

    changeset

    trait :deleted do
      visible false
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
