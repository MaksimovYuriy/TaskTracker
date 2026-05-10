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

### Уникальность `scheduled_at` глобальна, а не per-user

В текущей версии на уровне БД и валидации модели `Task` действует **глобальная уникальность** `scheduled_at`:

```ruby
# app/models/task.rb
validates :scheduled_at, uniqueness: true, allow_nil: true
```

```sql
CREATE UNIQUE INDEX index_tasks_on_scheduled_at ON tasks (scheduled_at);
```

Это сознательная сделка: ограничение **сейчас** защищает от дубликатов задач при повторных POST-запросах на создание серии (например, при двойном клике на «сохранить» на фронте) и от случайных пересечений времени. В однопользовательской системе это работает корректно.

**При добавлении модели `User` это ограничение нужно scope-нуть по `user_id`**, иначе два разных врача не смогут запланировать задачи на одно и то же время. Конкретные шаги:

1. Миграция `AddUserRefToTasks`:
   ```ruby
   add_reference :tasks, :user, foreign_key: true
   remove_index :tasks, :scheduled_at, unique: true
   add_index :tasks, [:user_id, :scheduled_at], unique: true
   ```
2. Валидация в `Task`:
   ```ruby
   validates :scheduled_at, uniqueness: { scope: :user_id }, allow_nil: true
   ```
3. Обновить `Materializer.duplicate?` — проверять в рамках пользователя, а не глобально.
4. В `MonthlyMaterializationJob.cleanup_orphans` тоже учитывать владельца.

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
