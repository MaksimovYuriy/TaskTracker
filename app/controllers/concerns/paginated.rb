# frozen_string_literal: true

module Paginated
  extend ActiveSupport::Concern

  included do
    include Pagy::Backend
  end

  private

  def pagination_meta(pagy_obj)
    {
      current_page: pagy_obj.page,
      per_page: pagy_obj.limit,
      total_pages: pagy_obj.pages,
      total_count: pagy_obj.count
    }
  end
end
