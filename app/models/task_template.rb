class TaskTemplate < ApplicationRecord
  enum :recurrence_type,
       { daily: 0, monthly: 1, specific_dates: 2, even_days: 3, odd_days: 4 },
       validate: true

  has_many :task_template_tags, dependent: :destroy
  has_many :tags,  through: :task_template_tags
  has_many :tasks, dependent: :nullify

  validates :title,           presence: true, length: { maximum: 255 }
  validates :description,     presence: true, length: { maximum: 5000 }
  validates :time_of_day,     presence: true
  validates :recurrence_type, presence: true

  with_options if: :daily? do
    validates :interval, presence: true,
                         numericality: { only_integer: true, greater_than: 0 }
  end

  with_options if: :monthly? do
    validates :day_of_month, presence: true,
                             numericality: { only_integer: true,
                                             greater_than_or_equal_to: 1,
                                             less_than_or_equal_to: 31 }
  end

  with_options if: :specific_dates? do
    validate :specific_dates_must_be_present
  end

  scope :active,          -> { where(active: true) }
  scope :with_recurrence, -> { where.not(recurrence_type: :specific_dates) }

  def cancel!
    update!(active: false)
  end

  private

  def specific_dates_must_be_present
    errors.add(:specific_dates, "не должны быть пустыми") if specific_dates.blank?
  end
end
