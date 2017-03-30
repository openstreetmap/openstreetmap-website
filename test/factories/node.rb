FactoryGirl.define do
  factory :node do
    latitude 1 * GeoRecord::SCALE
    longitude 1 * GeoRecord::SCALE

    changeset

    visible true
    timestamp Time.now
    version 1

    trait :with_history do
      after(:create) do |node, _evaluator|
        (1..node.version).each do |n|
          create(:old_node, :node_id => node.id, :version => n)
        end
      end
    end
  end
end
