# frozen_string_literal: true

class TagSerializer
  include JSONAPI::Serializer

  set_type :tag

  attributes :title

  attribute :system, &:system?
end
