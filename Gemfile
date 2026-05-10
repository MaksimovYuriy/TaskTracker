source "https://rubygems.org"

ruby "3.4.1"

gem "rails", "~> 7.1.6"

# PostgreSQL as the database for Active Record
gem "pg", "~> 1.5"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"

# JSON serialization
gem "jsonapi-serializer", "~> 2.2"

# Pagination
gem "pagy", "~> 9.0"

# Search/filtering
gem "ransack", "~> 4.2"

# CORS for cross-origin requests
gem "rack-cors", "~> 2.0"

# Background jobs
gem "sidekiq", "~> 7.3"
gem "sidekiq-cron", "~> 1.12"
gem "connection_pool", "~> 2.4"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# ostruct was removed from default gems in Ruby 3.5; pinned here while
# rswag-ui still depends on it transitively.
gem "ostruct"

# Swagger/OpenAPI runtime gems (mounted in routes)
gem "rswag-api", "~> 2.13"
gem "rswag-ui", "~> 2.13"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ]

  # RSpec test framework
  gem "rspec-rails", "~> 6.1"

  # OpenAPI generation from request specs
  gem "rswag-specs", "~> 2.13"

  # Test data factories
  gem "factory_bot_rails", "~> 6.4"
  gem "faker", "~> 3.4"
end

group :development do
  # Linter
  gem "rubocop-rails-omakase", require: false
end
