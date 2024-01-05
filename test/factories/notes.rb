FactoryBot.define do
  factory :note do
    latitude { 1 * GeoRecord::SCALE }
    longitude { 1 * GeoRecord::SCALE }
    # tile { QuadTile.tile_for_point(1,1) }

    trait :closed do
      transient do
        closed_by { nil }
      end

      status { "closed" }
      closed_at { Time.now.utc }

      after(:create) do |note, context|
        create(:note_comment, :author => context.closed_by, :body => "Closing comment", :event => "closed", :note => note)
      end
    end

    factory :note_with_comments do
      transient do
        comments_count { 1 }
      end

      after(:create) do |note, evaluator|
        create_list(:note_comment, evaluator.comments_count, :note => note)
      end
    end
  end
end
