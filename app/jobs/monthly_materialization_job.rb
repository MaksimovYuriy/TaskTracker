class MonthlyMaterializationJob
  include Sidekiq::Job

  sidekiq_options queue: :default

  def perform
    range = Time.current.beginning_of_month..Time.current.end_of_month

    TaskTemplate.active.with_recurrence.find_each do |template|
      TaskTemplates::Materializer.call(template, range: range)
    end

    cleanup_orphans
  end

  private

  def cleanup_orphans
    TaskTemplate.active.where.missing(:tasks).destroy_all
  end
end
