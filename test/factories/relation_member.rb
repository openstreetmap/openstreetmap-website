FactoryBot.define do
  factory :relation_member do
    member_role { "" }

    relation
    # Default to creating nodes, but could be ways or relations as members
    member :factory => :node
  end
end
