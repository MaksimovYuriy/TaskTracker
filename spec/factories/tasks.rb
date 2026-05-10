# frozen_string_literal: true

FactoryBot.define do
  factory :task do
    sequence(:title) { |n| "Task ##{n} - #{Faker::Lorem.sentence(word_count: 3)}" }
    description      { Faker::Lorem.paragraph(sentence_count: 3) }
    status           { :pending }
    scheduled_at     { Faker::Time.forward(days: 30) }
    sequence(:user_id) { |n| n }

    trait :done      do status { :done } end
    trait :cancelled do status { :cancelled } end

    trait :overdue do
      scheduled_at { Faker::Time.backward(days: 7) }
    end
  end
end
