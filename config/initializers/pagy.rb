# frozen_string_literal: true

require "pagy"

Pagy::DEFAULT[:limit] = 25
Pagy::DEFAULT[:max_limit] = 100
Pagy::DEFAULT[:page_param] = :page
Pagy::DEFAULT[:limit_param] = :per_page

require "pagy/extras/limit"
require "pagy/extras/headers"
require "pagy/extras/overflow"

Pagy::DEFAULT[:overflow] = :empty_page
Pagy::DEFAULT[:headers] = {
  page: "Current-Page",
  limit: "Page-Items",
  count: "Total-Count",
  pages: "Total-Pages"
}
