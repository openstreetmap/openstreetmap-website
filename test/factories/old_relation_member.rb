FactoryBot.define do
  factory :old_relation_member do
    sequence(:sequence_id)
    member_role { "" }

    old_relation
    # Default to creating nodes, but could be ways or relations as members
    member :factory => :node
  end
end
