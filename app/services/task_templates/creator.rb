# frozen_string_literal: true

module TaskTemplates
  class Creator < ApplicationService
    TEMPLATE_ATTRS = %i[
      title description recurrence_type interval day_of_month
      specific_dates time_of_day ends_at user_id
    ].freeze

    def initialize(params)
      @params = params
    end

    def call
      ApplicationRecord.transaction do
        template = TaskTemplate.create!(@params.slice(*TEMPLATE_ATTRS))
        template.tag_ids = @params[:tag_ids] if @params[:tag_ids].present?

        Materializer.call(template, range: initial_range(template))
      end
    end

    private

    def initial_range(template)
      if template.specific_dates?
        Time.current..Date.new(9999, 12, 31).end_of_day
      else
        Time.current..Time.current.end_of_month
      end
    end
  end
end
