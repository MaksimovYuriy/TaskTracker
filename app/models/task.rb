class Task < ApplicationRecord
  enum :status, { pending: 0, done: 1, cancelled: 2 }, validate: true

  belongs_to :task_template, optional: true

  has_many :task_tags, dependent: :destroy
  has_many :tags, through: :task_tags

  validates :title, presence: true, length: { maximum: 255 }
  validates :description, presence: true, length: { maximum: 5000 }
  validates :scheduled_at, uniqueness: true, allow_nil: true

  scope :scheduled_from, ->(time) { where("scheduled_at >= ?", time) }
  scope :scheduled_to,   ->(time) { where("scheduled_at <= ?", time) }

  def self.ransackable_attributes(_auth_object = nil)
    %w[status scheduled_at created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[tags]
  end
end
