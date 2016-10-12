FactoryGirl.define do
  factory :changeset_comment do
    sequence(:body) { |n| "Changeset comment #{n}" }
    visible true

    # FIXME: needs changeset factory
    changeset_id 3

    # FIXME: needs user factory
    author_id 1
  end
end
