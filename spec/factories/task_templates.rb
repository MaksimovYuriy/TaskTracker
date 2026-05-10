FactoryBot.define do
  factory :task_template do
    title { "MyString" }
    description { "MyText" }
    recurrence_type { 1 }
    interval { 1 }
    day_of_month { 1 }
    sepcific_dates { "2026-05-10" }
    time_of_day { "2026-05-10 10:36:41" }
    ends_at { "2026-05-10" }
    active { false }
  end
end
