class TagSerializer
  include JSONAPI::Serializer

  set_type :tag

  attributes :title

  attribute :system do |tag|
    tag.system?
  end
end
