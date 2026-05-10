# frozen_string_literal: true

module Api
  module V1
    class TasksController < BaseController
      before_action :set_task, only: %i[show update destroy]

      def index
        pagy_obj, tasks = pagy(TasksQuery.call(params))

        render json: TaskSerializer.new(tasks, include: [ :tags ]).serializable_hash.merge(
          meta: pagination_meta(pagy_obj)
        )
      end

      def show
        render json: TaskSerializer.new(@task, include: [ :tags ]).serializable_hash
      end

      def create
        result = Tasks::Creator.call(task_params)
        render json: TaskSerializer.new(result, include: [ :tags ]).serializable_hash, status: :created
      end

      def update
        @task.update!(update_params)
        render json: TaskSerializer.new(@task, include: [ :tags ]).serializable_hash
      end

      def destroy
        @task.destroy!
        head :no_content
      end

      def cancel_recurrence
        Tasks::RecurrenceCanceller.call(params[:id])
        head :no_content
      end

      private

      def set_task
        @task = Task.find(params[:id])
      end

      def task_params
        params.require(:task).permit(
          :title, :description, :status, :scheduled_at, :user_id,
          :recurrence_type, :interval, :day_of_month, :time_of_day, :ends_at,
          specific_dates: [], tag_ids: []
        )
      end

      def update_params
        params.require(:task).permit(:title, :description, :status, :scheduled_at)
      end
    end
  end
end
