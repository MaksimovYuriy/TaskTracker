# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'api/v1/tags', type: :request do
  path '/api/v1/tags' do
    get('list tags') do
      tags 'Tags'
      produces 'application/json'

      parameter name: :page,     in: :query, schema: { type: :integer }, required: false, description: 'Page number'
      parameter name: :per_page, in: :query, schema: { type: :integer }, required: false,
                description: 'Items per page (max 100)'

      response(200, 'list of tags') do
        schema '$ref' => '#/components/schemas/TagCollection'
        before { create_list(:tag, 3) }
        run_test!
      end
    end

    post('create tag') do
      tags 'Tags'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :tag_input, in: :body, schema: { '$ref' => '#/components/schemas/TagInput' }

      response(201, 'tag created') do
        schema '$ref' => '#/components/schemas/Tag'
        let(:tag_input) { { tag: { title: 'критично' } } }
        run_test!
      end

      response(400, 'parameter missing') do
        schema '$ref' => '#/components/schemas/Error'
        let(:tag_input) { {} }
        run_test!
      end

      response(422, 'validation error') do
        schema '$ref' => '#/components/schemas/Error'
        let(:tag_input) { { tag: { title: '' } } }
        run_test!
      end
    end
  end

  path '/api/v1/tags/{id}' do
    parameter name: :id, in: :path, type: :integer, required: true, description: 'Tag ID'

    get('show tag') do
      tags 'Tags'
      produces 'application/json'

      response(200, 'tag found') do
        schema '$ref' => '#/components/schemas/Tag'
        let(:id) { create(:tag).id }
        run_test!
      end

      response(404, 'tag not found') do
        schema '$ref' => '#/components/schemas/Error'
        let(:id) { 0 }
        run_test!
      end
    end

    patch('update tag') do
      tags 'Tags'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :tag_input, in: :body, schema: { '$ref' => '#/components/schemas/TagInput' }

      response(200, 'tag updated') do
        schema '$ref' => '#/components/schemas/Tag'
        let(:id) { create(:tag).id }
        let(:tag_input) { { tag: { title: 'обновлённый' } } }
        run_test!
      end

      response(400, 'parameter missing') do
        schema '$ref' => '#/components/schemas/Error'
        let(:id) { create(:tag).id }
        let(:tag_input) { {} }
        run_test!
      end

      response(404, 'tag not found') do
        schema '$ref' => '#/components/schemas/Error'
        let(:id) { 0 }
        let(:tag_input) { { tag: { title: 'X' } } }
        run_test!
      end

      response(422, 'system tag protected') do
        schema '$ref' => '#/components/schemas/Error'
        let(:id) { Tag.find_or_create_by!(title: Tag::SYSTEM_TITLES.first).id }
        let(:tag_input) { { tag: { title: 'другое' } } }
        run_test!
      end
    end

    delete('destroy tag') do
      tags 'Tags'

      response(204, 'tag destroyed') do
        let(:id) { create(:tag).id }
        run_test!
      end

      response(404, 'tag not found') do
        schema '$ref' => '#/components/schemas/Error'
        let(:id) { 0 }
        run_test!
      end

      response(422, 'system tag protected') do
        schema '$ref' => '#/components/schemas/Error'
        let(:id) { Tag.find_or_create_by!(title: Tag::SYSTEM_TITLES.first).id }
        run_test!
      end
    end
  end
end
