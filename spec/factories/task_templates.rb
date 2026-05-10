# frozen_string_literal: true

FactoryBot.define do
  factory :task_template do
    sequence(:title) { |n| "Template ##{n} - #{Faker::Lorem.sentence(word_count: 3)}" }
    description      { Faker::Lorem.paragraph(sentence_count: 3) }
    recurrence_type  { :daily }
    interval         { 1 }
    time_of_day      { '09:00' }
    active           { true }
    sequence(:user_id) { |n| n }

    trait :monthly do
      recurrence_type { :monthly }
      interval        { nil }
      day_of_month    { 15 }
    end

    trait :specific_dates do
      recurrence_type { :specific_dates }
      interval        { nil }
      specific_dates  { [ Date.current + 1.day, Date.current + 7.days ] }
    end

    trait :even_days do
      recurrence_type { :even_days }
      interval        { nil }
    end

    trait :odd_days do
      recurrence_type { :odd_days }
      interval        { nil }
    end

    trait :with_ends_at do
      ends_at { Date.current + 30.days }
    end

    trait :cancelled do
      active { false }
    end
  end
end
