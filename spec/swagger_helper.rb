# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  config.openapi_root = Rails.root.join('swagger').to_s

  config.openapi_specs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'Task Tracker API',
        version: 'v1',
        description: 'API трекера задач для МИС'
      },
      servers: [
        {
          url: 'http://{defaultHost}',
          variables: {
            defaultHost: { default: 'localhost:3000' }
          }
        }
      ],
      components: {
        schemas: {
          Task: {
            type: :object,
            properties: {
              data: { '$ref' => '#/components/schemas/TaskResource' }
            },
            required: %w[data]
          },
          TaskCollection: {
            type: :object,
            properties: {
              data: {
                type: :array,
                items: { '$ref' => '#/components/schemas/TaskResource' }
              },
              meta: { '$ref' => '#/components/schemas/PaginationMeta' }
            },
            required: %w[data meta]
          },
          TaskResource: {
            type: :object,
            properties: {
              id: { type: :string, example: '1' },
              type: { type: :string, enum: ['task'] },
              attributes: {
                type: :object,
                properties: {
                  title: { type: :string, example: 'Обход пациентов' },
                  description: { type: :string, example: 'Палаты 201–215, проверить капельницы' },
                  status: { type: :string, enum: %w[pending done cancelled] },
                  scheduled_at: { type: :string, format: 'date-time', nullable: true }
                },
                required: %w[title description status scheduled_at]
              }
            },
            required: %w[id type attributes]
          },
          TaskInput: {
            type: :object,
            properties: {
              task: {
                type: :object,
                properties: {
                  title: { type: :string, example: 'Обход пациентов' },
                  description: { type: :string, example: 'Палаты 201–215, проверить капельницы' },
                  status: { type: :string, enum: %w[pending done cancelled] },
                  scheduled_at: { type: :string, format: 'date-time' }
                },
                required: %w[title description]
              }
            },
            required: %w[task]
          },
          PaginationMeta: {
            type: :object,
            properties: {
              current_page: { type: :integer, example: 1 },
              per_page: { type: :integer, example: 25 },
              total_pages: { type: :integer, example: 4 },
              total_count: { type: :integer, example: 87 }
            },
            required: %w[current_page per_page total_pages total_count]
          },
          Error: {
            type: :object,
            properties: {
              errors: {
                type: :array,
                items: {
                  type: :object,
                  properties: {
                    status: { type: :string, example: '422' },
                    code: { type: :string, example: 'validation_error' },
                    detail: { type: :string, example: "Title can't be blank" },
                    source: {
                      type: :object,
                      properties: {
                        pointer: { type: :string, example: '/data/attributes/title' }
                      }
                    }
                  },
                  required: %w[status code detail]
                }
              }
            },
            required: %w[errors]
          }
        }
      },
      paths: {}
    }
  }

  config.openapi_format = :yaml
end
