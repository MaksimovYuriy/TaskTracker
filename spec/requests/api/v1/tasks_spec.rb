require 'swagger_helper'

RSpec.describe 'api/v1/tasks', type: :request do
  path '/api/v1/tasks' do
    get('list tasks') do
      tags 'Tasks'
      produces 'application/json'

      parameter name: :page,                 in: :query, schema: { type: :integer }, required: false, description: 'Page number'
      parameter name: :per_page,             in: :query, schema: { type: :integer }, required: false, description: 'Items per page (max 100)'
      parameter name: :'q[status_eq]',       in: :query, schema: { type: :string, enum: %w[pending done cancelled] }, required: false
      parameter name: :'q[scheduled_at_gteq]', in: :query, schema: { type: :string, format: 'date-time' }, required: false
      parameter name: :'q[scheduled_at_lteq]', in: :query, schema: { type: :string, format: 'date-time' }, required: false
      parameter name: :'q[tags_id_in][]',     in: :query, schema: { type: :array, items: { type: :integer } }, required: false, description: 'Filter by tag ids (OR semantics)'
      parameter name: :'q[tags_title_in][]',  in: :query, schema: { type: :array, items: { type: :string } },  required: false, description: 'Filter by tag titles (OR semantics)'

      response(200, 'list of tasks') do
        schema '$ref' => '#/components/schemas/TaskCollection'
        before { create_list(:task, 3) }
        run_test!
      end
    end

    post('create task') do
      tags 'Tasks'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :task_input, in: :body, schema: { '$ref' => '#/components/schemas/TaskInput' }

      response(201, 'task created') do
        schema '$ref' => '#/components/schemas/Task'
        let(:task_input) do
          {
            task: {
              title: 'Обход пациентов',
              description: 'Палаты 201–215, проверить капельницы и температуру',
              status: 'pending',
              scheduled_at: 1.day.from_now.iso8601
            }
          }
        end
        run_test!
      end

      response(400, 'parameter missing') do
        schema '$ref' => '#/components/schemas/Error'
        let(:task_input) { {} }
        run_test!
      end

      response(422, 'validation error') do
        schema '$ref' => '#/components/schemas/Error'
        let(:task_input) { { task: { title: '', description: '', status: 'pending' } } }
        run_test!
      end
    end
  end

  path '/api/v1/tasks/{id}' do
    parameter name: :id, in: :path, type: :integer, required: true, description: 'Task ID'

    get('show task') do
      tags 'Tasks'
      produces 'application/json'

      response(200, 'task found') do
        schema '$ref' => '#/components/schemas/Task'
        let(:id) { create(:task).id }
        run_test!
      end

      response(404, 'task not found') do
        schema '$ref' => '#/components/schemas/Error'
        let(:id) { 0 }
        run_test!
      end
    end

    patch('update task') do
      tags 'Tasks'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :task_input, in: :body, schema: { '$ref' => '#/components/schemas/TaskInput' }

      response(200, 'task updated') do
        schema '$ref' => '#/components/schemas/Task'
        let(:id) { create(:task).id }
        let(:task_input) { { task: { title: 'Обновлённый заголовок' } } }
        run_test!
      end

      response(400, 'parameter missing') do
        schema '$ref' => '#/components/schemas/Error'
        let(:id) { create(:task).id }
        let(:task_input) { {} }
        run_test!
      end

      response(404, 'task not found') do
        schema '$ref' => '#/components/schemas/Error'
        let(:id) { 0 }
        let(:task_input) { { task: { title: 'X' } } }
        run_test!
      end

      response(422, 'validation error') do
        schema '$ref' => '#/components/schemas/Error'
        let(:id) { create(:task).id }
        let(:task_input) { { task: { title: '' } } }
        run_test!
      end
    end

    delete('delete task') do
      tags 'Tasks'

      response(204, 'task deleted') do
        let(:id) { create(:task).id }
        run_test!
      end

      response(404, 'task not found') do
        schema '$ref' => '#/components/schemas/Error'
        let(:id) { 0 }
        run_test!
      end
    end
  end
end
