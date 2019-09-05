FactoryBot.define do
  factory :event_attendance do
    user_id { 1 }
    event_id { 1 }
    intention { "MyString" }
  end
end
