FactoryBot.define do
  factory :note_tag do
    sequence(:k) { |n| "Key #{n}" }
    sequence(:v) { |n| "Value #{n}" }

    note
  end
end
