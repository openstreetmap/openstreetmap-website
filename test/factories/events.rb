FactoryBot.define do
  factory :event do
    title { "MyString" }
    moment { "2019-09-05 12:08:02" }
    location { "MyString" }
    description { "MyText" }
    microcosm_id { 1 }
  end
end
