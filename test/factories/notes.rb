FactoryGirl.define do
  factory :note do
    latitude 1 * GeoRecord::SCALE
    longitude 1 * GeoRecord::SCALE
    # tile QuadTile.tile_for_point(1,1)

    factory :note_with_comments do
      transient do
        comments_count 1
      end

      after(:create) do |note, evaluator|
        create_list(:note_comment, evaluator.comments_count, :note => note)
      end
    end
  end
end
