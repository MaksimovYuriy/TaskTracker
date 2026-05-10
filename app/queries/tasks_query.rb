# frozen_string_literal: true

class TasksQuery < ApplicationService
  def initialize(params)
    @params = params
  end

  def call
    Task.ransack(@params[:q]).result
        .includes(:tags).distinct
        .order(scheduled_at: :asc, id: :asc)
  end
end
