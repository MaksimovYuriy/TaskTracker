require 'swagger_helper'

RSpec.describe 'api/v1/tasks/:task_id/tags', type: :request do
  path '/api/v1/tasks/{task_id}/tags' do
    parameter name: :task_id, in: :path, type: :integer, required: true, description: 'Task ID'

    post('attach tag to task') do
      tags 'TaskTags'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :attach_input, in: :body, schema: { '$ref' => '#/components/schemas/AttachTagInput' }

      response(200, 'tag attached (idempotent)') do
        schema '$ref' => '#/components/schemas/Task'
        let(:task_id) { create(:task).id }
        let(:attach_input) { { tag_id: create(:tag).id } }
        run_test!
      end

      response(400, 'parameter missing') do
        schema '$ref' => '#/components/schemas/Error'
        let(:task_id) { create(:task).id }
        let(:attach_input) { {} }
        run_test!
      end

      response(404, 'task or tag not found') do
        schema '$ref' => '#/components/schemas/Error'
        let(:task_id) { 0 }
        let(:attach_input) { { tag_id: create(:tag).id } }
        run_test!
      end
    end
  end

  path '/api/v1/tasks/{task_id}/tags/{id}' do
    parameter name: :task_id, in: :path, type: :integer, required: true, description: 'Task ID'
    parameter name: :id,      in: :path, type: :integer, required: true, description: 'Tag ID'

    delete('detach tag from task') do
      tags 'TaskTags'

      response(204, 'tag detached') do
        let(:task) { create(:task) }
        let(:tag)  { create(:tag) }
        let(:task_id) { task.id }
        let(:id)      { tag.id }
        before { task.tags << tag }
        run_test!
      end

      response(404, 'task not found or tag not attached') do
        schema '$ref' => '#/components/schemas/Error'
        let(:task_id) { 0 }
        let(:id) { 0 }
        run_test!
      end
    end
  end
end
