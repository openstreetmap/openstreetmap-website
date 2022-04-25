FactoryBot.define do
  factory :old_way_node do
    sequence_id { 1 }

    old_way
    node
  end
end
