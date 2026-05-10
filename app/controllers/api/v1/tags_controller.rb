# frozen_string_literal: true

module Api
  module V1
    class TagsController < BaseController
      before_action :set_tag, only: %i[show update destroy]

      def index
        scope = Tag.all.order(:title)
        pagy_obj, tags = pagy(scope)

        render json: TagSerializer.new(tags).serializable_hash.merge(
          meta: pagination_meta(pagy_obj)
        )
      end

      def show
        render json: TagSerializer.new(@tag).serializable_hash
      end

      def create
        tag = Tag.create!(tag_params)
        render json: TagSerializer.new(tag).serializable_hash, status: :created
      end

      def update
        @tag.update!(tag_params)
        render json: TagSerializer.new(@tag).serializable_hash
      end

      def destroy
        @tag.destroy!
        head :no_content
      end

      private

      def set_tag
        @tag = Tag.find(params[:id])
      end

      def tag_params
        params.require(:tag).permit(:title)
      end
    end
  end
end
