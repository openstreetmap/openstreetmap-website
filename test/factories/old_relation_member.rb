FactoryGirl.define do
  factory :old_relation_member do
    member_role ""

    old_relation
    # Default to creating nodes, but could be ways or relations as members
    association :member, :factory => :node
  end
end
