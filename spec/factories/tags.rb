# frozen_string_literal: true

FactoryBot.define do
  factory :tag do
    sequence(:title) { |n| "tag_#{n}_#{Faker::Lorem.word}" }
  end
end
