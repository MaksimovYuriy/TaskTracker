module TaskTemplates
  class Materializer
    STRATEGY_CLASSES = {
      "daily"          => "TaskTemplates::Recurrence::DailyStrategy",
      "monthly"        => "TaskTemplates::Recurrence::MonthlyStrategy",
      "specific_dates" => "TaskTemplates::Recurrence::SpecificDatesStrategy",
      "even_days"      => "TaskTemplates::Recurrence::EvenDaysStrategy",
      "odd_days"       => "TaskTemplates::Recurrence::OddDaysStrategy"
    }.freeze

    def self.call(template, range:)
      new(template, range: range).call
    end

    def initialize(template, range:)
      @template = template
      @range = range
    end

    def call
      strategy_class.call(@template, range: @range)
                    .filter_map { |scheduled_at| materialize(scheduled_at) }
    end

    private

    def strategy_class
      STRATEGY_CLASSES.fetch(@template.recurrence_type).constantize
    end

    def materialize(scheduled_at)
      return if duplicate?(scheduled_at)

      task = @template.tasks.create!(
        title:        @template.title,
        description:  @template.description,
        scheduled_at: scheduled_at,
        status:       :pending
      )
      copy_tags_to(task)
      task
    rescue ActiveRecord::RecordNotUnique
      nil
    end

    def duplicate?(scheduled_at)
      Task.exists?(scheduled_at: scheduled_at)
    end

    def copy_tags_to(task)
      task.tag_ids = @template.tag_ids if @template.tag_ids.any?
    end
  end
end
