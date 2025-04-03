FactoryBot.define do
  factory :note_tag_version do
    sequence(:k) { |n| "Key #{n}" }
    sequence(:v) { |n| "Value #{n}" }

    note_version
  end
end
