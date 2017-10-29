FactoryBot.define do
  factory :node do
    latitude 1 * GeoRecord::SCALE
    longitude 1 * GeoRecord::SCALE

    changeset

    visible true
    timestamp Time.now
    version 1

    trait :deleted do
      visible false
    end

    trait :with_history do
      after(:create) do |node, _evaluator|
        (1..node.version).each do |n|
          create(:old_node, :node_id => node.id, :version => n, :changeset => node.changeset)
        end

        # For deleted nodes, make sure the most recent old_node is also deleted.
        if node.visible == false
          latest = node.old_nodes.find_by(:version => node.version)
          latest.visible = false
          latest.save
        end
      end
    end
  end
end
