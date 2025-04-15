# frozen_string_literal: true

FactoryBot.define do
  factory :old_relation do
    timestamp { Time.now.utc }
    visible { true }
    version { 1 }

    changeset
    current_relation :factory => :relation
  end
end
