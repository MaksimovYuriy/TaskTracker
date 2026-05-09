module Api
  module V1
    class TaskTagsController < BaseController
      before_action :set_task

      def create
        tag = Tag.find(params.require(:tag_id))
        @task.tags << tag unless @task.tags.include?(tag)
        render json: TaskSerializer.new(@task.reload, include: [:tags]).serializable_hash
      end

      def destroy
        tag = @task.tags.find(params[:id])
        @task.tags.destroy(tag)
        head :no_content
      end

      private

      def set_task
        @task = Task.find(params[:task_id])
      end
    end
  end
end
