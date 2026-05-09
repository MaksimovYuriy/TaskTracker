module Api
  module V1
    class BaseController < ActionController::API
      include Pagy::Backend
      include ApiErrorHelper

      rescue_from ActiveRecord::RecordNotFound,
                  ActiveRecord::RecordInvalid,
                  ActionController::ParameterMissing,
                  Tag::SystemTagProtected do |exception|
        render(**error_response_for(exception))
      end
    end
  end
end
