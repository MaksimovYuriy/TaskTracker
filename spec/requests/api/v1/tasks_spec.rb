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

      parameter name: :task_input, in: :body, schema: { '$ref' => '#/components/schemas/TaskCreateInput' }

      response(201, 'single task or recurring series created') do
        schema oneOf: [
          { '$ref' => '#/components/schemas/Task' },
          { '$ref' => '#/components/schemas/TaskBatch' }
        ]

        context 'single task' do
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

        context 'daily recurrence' do
          let(:task_input) do
            {
              task: {
                title: 'Утренний обход',
                description: 'Каждый день, проверка ИВЛ',
                recurrence_type: 'daily',
                interval: 1,
                time_of_day: '09:00'
              }
            }
          end
          run_test!
        end

        context 'monthly recurrence' do
          let(:task_input) do
            {
              task: {
                title: 'Ежемесячный отчёт',
                description: 'Сводка за месяц',
                recurrence_type: 'monthly',
                day_of_month: 15,
                time_of_day: '12:00'
              }
            }
          end
          run_test!
        end

        context 'specific dates recurrence' do
          let(:task_input) do
            {
              task: {
                title: 'Консилиум',
                description: 'Запланированный осмотр',
                recurrence_type: 'specific_dates',
                specific_dates: [(Date.current + 3.days).to_s, (Date.current + 10.days).to_s],
                time_of_day: '10:30'
              }
            }
          end
          run_test!
        end

        context 'even days recurrence' do
          let(:task_input) do
            {
              task: {
                title: 'Зарядка пациентов',
                description: 'Лечебная физкультура',
                recurrence_type: 'even_days',
                time_of_day: '08:00'
              }
            }
          end
          run_test!
        end

        context 'odd days recurrence' do
          let(:task_input) do
            {
              task: {
                title: 'Перевязки',
                description: 'Палаты 301-310',
                recurrence_type: 'odd_days',
                time_of_day: '11:00'
              }
            }
          end
          run_test!
        end

        context 'duplicate POST returns empty data (slots already taken)' do
          before do
            existing = create(:task_template)
            create(:task, task_template: existing, scheduled_at: 1.day.from_now.change(hour: 9, min: 0))
          end
          let(:task_input) do
            {
              task: {
                title: 'Утренний обход',
                description: 'Палаты 201-215',
                recurrence_type: 'daily',
                interval: 1,
                time_of_day: Time.current.tomorrow.change(hour: 9, min: 0).strftime('%H:%M')
              }
            }
          end
          run_test!
        end
      end

      response(400, 'parameter missing') do
        schema '$ref' => '#/components/schemas/Error'
        let(:task_input) { {} }
        run_test!
      end

      response(422, 'validation error') do
        schema '$ref' => '#/components/schemas/Error'

        context 'empty title and description' do
          let(:task_input) { { task: { title: '', description: '', status: 'pending' } } }
          run_test!
        end

        context 'daily recurrence without interval' do
          let(:task_input) do
            {
              task: {
                title: 'Битый шаблон',
                description: '...',
                recurrence_type: 'daily',
                time_of_day: '09:00'
              }
            }
          end
          run_test!
        end
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

      parameter name: :task_input, in: :body, schema: { '$ref' => '#/components/schemas/TaskUpdateInput' }

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

  path '/api/v1/tasks/{id}/recurrence' do
    parameter name: :id, in: :path, type: :integer, required: true, description: 'Task ID'

    delete('cancel recurring series') do
      tags 'Tasks'
      description 'Отменяет всю серию повторений: помечает шаблон неактивным и удаляет все будущие pending-задачи серии (включая текущую). Идемпотентно — для задачи без серии возвращает 204 без изменений.'

      response(204, 'recurrence cancelled (or task not in series — no-op)') do
        context 'task is part of a recurring series' do
          let(:id) do
            template = create(:task_template)
            create(:task, task_template: template, scheduled_at: 1.day.from_now).id
          end
          run_test!
        end

        context 'task is not part of any series (idempotent no-op)' do
          let(:id) { create(:task).id }
          run_test!
        end
      end

      response(404, 'task not found') do
        schema '$ref' => '#/components/schemas/Error'
        let(:id) { 0 }
        run_test!
      end
    end
  end
end
