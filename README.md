# Task Tracker API

API-модуль трекера рабочих задач для медицинской информационной системы (МИС). Через модуль врачи и администраторы ставят задачи: операции, обходы, отчёты, звонки и т.п. Поддерживается периодичность задач (ежедневные, ежемесячные, на конкретные даты, чёт/нечет дни месяца) и теги.

## Стек

- **Ruby** 3.4.1
- **Rails** 7.1 (API-only)
- **PostgreSQL** 16+
- **Redis** + **Sidekiq** (фоновые задачи, cron-расписание через `sidekiq-cron`)
- **JSON:API** через `jsonapi-serializer`
- **Pagy** + **Ransack** — пагинация и фильтрация
- **rswag** — OpenAPI/Swagger из request-spec'ов

## Запуск

```bash
bundle install
bin/rails db:setup              # create + migrate + seed (системные теги)
bin/rails s                     # API на http://localhost:3000
bundle exec sidekiq             # воркер с cron-задачей материализации
```

OpenAPI UI: `http://localhost:3000/api-docs`
Sidekiq UI: `http://localhost:3000/sidekiq`

## Тесты

```bash
bundle exec rspec
bundle exec rake rswag:specs:swaggerize   # перегенерировать swagger.yaml
```

## Известные ограничения и план развития

### `user_id` сейчас — placeholder без модели `User`

В таблицах `tasks` и `task_templates` уже есть колонка `user_id` (`bigint`, nullable, без foreign key). Уникальность `scheduled_at` уже scope-нута по `user_id`:

```ruby
# app/models/task.rb
validates :scheduled_at, presence: true, uniqueness: { scope: :user_id }
```

```sql
CREATE UNIQUE INDEX index_tasks_on_user_id_and_scheduled_at ON tasks (user_id, scheduled_at);
```

Сейчас фронт может присылать `user_id` в payload'е (`POST /api/v1/tasks`), а материализатор копирует `user_id` из шаблона в каждую дочернюю задачу. Это **временный механизм-допущение** до появления реальной авторизации.

**Что нужно сделать при добавлении модели `User` и аутентификации:**

1. Миграция `AddUsersAndForeignKeys`:
   ```ruby
   create_table :users do |t|
     # email, password_digest, name, role и т.п.
     t.timestamps
   end
   change_column_null :tasks,          :user_id, false
   change_column_null :task_templates, :user_id, false
   add_foreign_key :tasks,          :users
   add_foreign_key :task_templates, :users
   ```
2. В моделях `Task` и `TaskTemplate`:
   ```ruby
   belongs_to :user
   validates :user_id, presence: true
   ```
3. В `BaseController` — `before_action :authenticate_user!`, экспозиция `current_user`.
4. В `TasksController#task_params` — убрать `:user_id` из `permit` (нельзя позволять клиенту подменять владельца) и подставлять `current_user.id` в сервис явно.
5. В `index` и `show` добавить scope: `Task.where(user_id: current_user.id)`. Аналогично в управлении тегами и материализации.

### Прочее, что отложено до фичи авторизации

- Аутентификация (JWT / OAuth) и `before_action :authenticate_user!`.
- Гранулярные политики доступа (роли doctor/admin, права на чужие задачи и шаблоны).
- Soft-delete тегов системного назначения (сейчас защищён константой `Tag::SYSTEM_TITLES`, при многопользовательской модели может потребоваться пересмотр).

### Edit шаблона

Сейчас редактирование `TaskTemplate` через API не поддерживается — только создание (`POST /api/v1/tasks` с recurrence-полями) и отмена серии (`DELETE /api/v1/tasks/:id/recurrence`). Если правило надо изменить, отменяется текущая серия и создаётся новая. Если возникнет реальный спрос на in-place edit с пропагацией изменений на дочерние задачи — добавляется отдельным эндпоинтом.

## Структура

- [HISTORY.md](HISTORY.md) — журнал проектных решений и обсуждений по фичам.
- `app/services/` — бизнес-логика (тонкие контроллеры, толстые сервисы).
- `app/jobs/MonthlyMaterializationJob` — раз в месяц материализует дочерние задачи активных шаблонов и подчищает орфаны.
- `spec/requests/api/v1/` — request-spec'ы, источник OpenAPI-документации.
