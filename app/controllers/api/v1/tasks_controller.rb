module Api
  module V1
    class TasksController < BaseController
      before_action :set_task, only: %i[show update destroy]

      def index
        scope = Task.ransack(params[:q]).result.includes(:tags).order(scheduled_at: :asc, id: :asc)
        pagy_obj, tasks = pagy(scope)

        render json: TaskSerializer.new(tasks, include: [:tags]).serializable_hash.merge(
          meta: pagination_meta(pagy_obj)
        )
      end

      def show
        render json: TaskSerializer.new(@task, include: [:tags]).serializable_hash
      end

      def create
        task = Task.create!(task_params)
        render json: TaskSerializer.new(task, include: [:tags]).serializable_hash, status: :created
      end

      def update
        @task.update!(task_params)
        render json: TaskSerializer.new(@task, include: [:tags]).serializable_hash
      end

      def destroy
        @task.destroy!
        head :no_content
      end

      private

      def set_task
        @task = Task.find(params[:id])
      end

      def task_params
        params.require(:task).permit(:title, :description, :status, :scheduled_at)
      end

      def pagination_meta(pagy_obj)
        {
          current_page: pagy_obj.page,
          per_page: pagy_obj.limit,
          total_pages: pagy_obj.pages,
          total_count: pagy_obj.count
        }
      end
    end
  end
end
