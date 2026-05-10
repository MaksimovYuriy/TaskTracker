module Tasks
  class Creator
    SINGLE_TASK_ATTRS = %i[title description status scheduled_at].freeze

    def self.call(params)
      new(params).call
    end

    def initialize(params)
      @params = params
    end

    def call
      if recurring?
        TaskTemplates::Creator.call(@params)
      else
        [Task.create!(@params.slice(*SINGLE_TASK_ATTRS))]
      end
    end

    private

    def recurring?
      @params[:recurrence_type].present?
    end
  end
end
