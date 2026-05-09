class Tag < ApplicationRecord
  SYSTEM_TITLES = %w[отчётность операции звонок].freeze

  class SystemTagProtected < StandardError
    def initialize(msg = "Системные теги нельзя изменять или удалять")
      super
    end
  end

  has_many :task_tags, dependent: :destroy
  has_many :tasks, through: :task_tags

  validates :title, presence: true,
                    length: { maximum: 32 },
                    uniqueness: { case_sensitive: false }

  before_update  :prevent_system_modification
  before_destroy :prevent_system_destruction

  scope :system_tags, -> { where(title: SYSTEM_TITLES) }
  scope :user_tags,   -> { where.not(title: SYSTEM_TITLES) }

  def self.ransackable_attributes(_auth_object = nil)
    %w[id title]
  end

  def system?
    SYSTEM_TITLES.include?(title)
  end

  private

  def prevent_system_modification
    raise SystemTagProtected if title_was.in?(SYSTEM_TITLES) && title_changed?
  end

  def prevent_system_destruction
    raise SystemTagProtected if system?
  end
end
