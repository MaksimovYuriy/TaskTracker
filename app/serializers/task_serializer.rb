class TaskSerializer
  include JSONAPI::Serializer

  set_type :task

  attributes :title, :description, :status, :scheduled_at

  attribute :task_template_id do |task|
    task.task_template_id&.to_s
  end

  has_many :tags
end
