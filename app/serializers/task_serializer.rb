class TaskSerializer
  include JSONAPI::Serializer

  set_type :task

  attributes :title, :description, :status, :scheduled_at

  has_many :tags
end
