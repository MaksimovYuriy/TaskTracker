class Task < ApplicationRecord
  enum :status, { pending: 0, done: 1, cancelled: 2 }, validate: true

  validates :title, presence: true, length: { maximum: 255 }
  validates :description, presence: true, length: { maximum: 5000 }

  scope :scheduled_from, ->(time) { where("scheduled_at >= ?", time) }
  scope :scheduled_to,   ->(time) { where("scheduled_at <= ?", time) }

  def self.ransackable_attributes(_auth_object = nil)
    %w[status scheduled_at created_at]
  end
end
