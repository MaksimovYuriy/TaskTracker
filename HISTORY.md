# История разработки Task Tracker API

Журнал проектных решений и обсуждений по ходу разработки. Каждый раздел — один логический шаг работы (фича или подфича). Формируется в конце каждого этапа.

**Контекст проекта:** API-модуль трекера рабочих задач для медицинской информационной системы (МИС). Через модуль врачи и администраторы ставят себе задачи: операции, обходы, отчёты, звонки.

---

## Шаг 0. Стек и инфраструктура

### Обсуждали
- Выбор гемов: сериализация, пагинация, фильтрация, документация API.
- БД: оставить SQLite или сразу PostgreSQL.
- Версии Ruby и PostgreSQL.

### Решения
- **Ruby 3.4.1** через `rbenv local` — изолировано в директории проекта.
- **PostgreSQL 16+** — у пользователя локально 16.13, подходит.
- **Сериализация:** `jsonapi-serializer` (формат JSON:API для полноты и стандартизации).
- **Пагинация и фильтры:** `pagy` + `ransack`.
- **OpenAPI/Swagger:** `rswag` (схемы из request-spec'ов, документация автоматически совпадает с поведением).
- **CORS:** `rack-cors`, origins из `CORS_ORIGINS`.
- **Тесты:** RSpec + FactoryBot + Faker.

### Реализовано
- `Gemfile` обновлён под выбранный стек, добавлен `gem "ostruct"` (для совместимости с Ruby 3.4 + rswag-ui).
- `config/database.yml` переведён на PostgreSQL с переменными окружения.
- `config/initializers/cors.rb` — настроен CORS.
- `config/initializers/pagy.rb` — пагинация по `?page=N&per_page=M`, лимиты 25/100, метаданные.
- `Dockerfile` — `libsqlite3-0` → `libpq5`, добавлен `libpq-dev` в build-стадию.
- `.gitignore` — добавлены `.idea/`, `.vscode/`, `.claude/`, `coverage/`.

---

## Шаг 1. CRUD по задачам (`Task`)

### Обсуждали
- Состав модели на старте: `title`, `description`, `status`, `scheduled_at`.
- Статусы: остановились на `pending / done / cancelled` (без `in_progress`).
- Аутентификация — пока не делаем.
- Формат ответа: JSON:API (`{ data: { id, type, attributes } }`).
- Версионирование URL: `api/v1/...`, явный `only:` в `resources`.
- Обработка ошибок: где её держать (отдельный класс, концерн или helper).
- Индексы в БД — нужны ли при текущем масштабе.

### Решения
- **Поля задачи:** `title` (presence, max 255), `description` (presence, max 5000 — медицина требует конкретики), `status` (enum с `validate: true`), `scheduled_at`.
- **Сортировка по умолчанию:** `scheduled_at asc, id asc` — без неё пагинация может скакать.
- **Пагинация:** через `meta` в теле ответа (а не headers) — последовательно с JSON:API.
- **Дубликаты при `status = "garbage"`:** через `enum :status, ..., validate: true` — невалидное значение становится `RecordInvalid`, ловит общий обработчик.
- **Обработка ошибок:** вынесли в helper `ApiErrorHelper` (SRP: helper отвечает только за форматирование, BaseController — за wiring через `rescue_from`). Методы приватные.
- **Индексы:** добавили только `index :scheduled_at`. От индекса по `status` отказались — низкая кардинальность (3 значения), Postgres всё равно не использует. От composite в `task_tags` — отказались позже (см. шаг 2).
- **Тесты:** request-spec'ы через `rswag`, полное покрытие всех возможных статус-кодов каждого эндпоинта (12 тестов).

### Реализовано
- Миграции: `create_tasks`, `add_status_to_task`, `add_index_to_task_scheduled_at`.
- `app/models/task.rb` — enum, валидации, скоупы `scheduled_from/to`, ransack whitelist.
- `app/serializers/task_serializer.rb` — атрибуты `title`, `description`, `status`, `scheduled_at` (без timestamps — это системные поля).
- `app/helpers/api_error_helper.rb` — три метода: `error_response_for`, `record_errors`, `single_error`.
- `app/controllers/api/v1/base_controller.rb` — включает `Pagy::Backend` и `ApiErrorHelper`, один `rescue_from` на четыре класса исключений.
- `app/controllers/api/v1/tasks_controller.rb` — CRUD (5 экшенов) + ransack-фильтры + пагинация.
- `config/routes.rb` — `namespace :api do; namespace :v1 do; resources :tasks, only: %i[index show create update destroy]`.
- `spec/factories/tasks.rb` — sequence для уникальных заголовков, трейты `:done`, `:cancelled`, `:overdue`, `FactoryBot.lint` в `before(:suite)`.
- `spec/swagger_helper.rb` — компоненты `Task`, `TaskCollection`, `TaskResource`, `TaskInput`, `PaginationMeta`, `Error`.
- `spec/requests/api/v1/tasks_spec.rb` — 12 тестов (200/201/204/400/404/422 по эндпоинтам).

---

## Шаг 2. Теги (`Tag`, `TaskTag`)

### Обсуждали
- Связь Task ↔ Tag: HABTM или явная join-модель.
- Системные теги: колонка-флаг или константа в модели.
- Вариант API связи: bulk-replace (Вариант A: `tag_ids` в PATCH задачи) vs sub-resource (Вариант Б: `POST/DELETE /tasks/:id/tags`).
- Уникальный индекс на `tags.title` — нужен ли при нашем масштабе.
- Composite unique индекс `[task_id, tag_id]` в join-таблице — нужен ли.
- HTTP-код для блокировки изменения системного тега.
- Идемпотентность POST на уже привязанный тег.

### Решения
- **Join-модель явная** — `TaskTag` (на будущее, чтобы можно было хранить «когда» и «кем»).
- **Системные теги через константу** `Tag::SYSTEM_TITLES = %w[отчётность операции звонок]` — без отдельной колонки. Если завтра нужно сделать произвольные теги «системными» — введём колонку.
- **Защита через кастомное исключение** `Tag::SystemTagProtected < StandardError`. Колбэки `before_update`/`before_destroy` его бросают — `ApiErrorHelper` ловит и отдаёт 422.
- **Связь — Вариант Б (sub-resource).** Аргументы: чистые атомарные операции для возможной инлайн-UX, аудит-friendly (важно для МИС), гранулярная авторизация в будущем. Логика в контроллере (3 строки на экшен), без сервисного слоя.
- **Без индексов** — от unique на `tags.title` отказались (таблица крошечная, race condition не страшен), от composite на `[task_id, tag_id]` отказались (Rails-уровневая `validates uniqueness scope: :tag_id` достаточна).
- **422 на блокировку** — последовательно с другими бизнес-правилами.
- **Идемпотентный POST** — если тег уже привязан, возвращаем 200 с обновлённой задачей. Без создания дублей.
- **Атрибут `system` в сериализаторе виртуальный** — вычисляется через `tag.system?` в block-форме, не хранится в БД.
- **Поле — `title`** (как назвал пользователь), валидации: `presence`, `length: { maximum: 32 }`, `uniqueness: { case_sensitive: false }`. На уровне БД: `null: false`, `limit: 32`.
- **Сидs** через `db/seeds.rb`, идемпотентно (`find_or_create_by!`).

### Реализовано
- Миграции: `create_tags` (после rollback и редактирования с null:false/limit:32), `create_task_tags`.
- `app/models/tag.rb` — константа, `SystemTagProtected`, валидации, колбэки, скоупы, `ransackable_attributes`.
- `app/models/task_tag.rb` — `belongs_to :task/:tag`, `validates :task_id, uniqueness: { scope: :tag_id }`.
- `app/models/task.rb` — добавлены `has_many :task_tags, dependent: :destroy` и `has_many :tags, through: :task_tags`.
- `app/helpers/api_error_helper.rb` — добавлена ветка `Tag::SystemTagProtected → 422`.
- `app/controllers/api/v1/base_controller.rb` — добавлен `Tag::SystemTagProtected` в `rescue_from`.
- `app/serializers/tag_serializer.rb` — `title` + виртуальный `system`.
- `app/serializers/task_serializer.rb` — добавлен `has_many :tags`.
- `app/controllers/api/v1/tags_controller.rb` — обычный CRUD.
- `app/controllers/api/v1/task_tags_controller.rb` — идемпотентный create + destroy.
- `app/controllers/api/v1/tasks_controller.rb` — все рендеры зовут `TaskSerializer.new(task, include: [:tags])`, в `index` добавлен `.includes(:tags)` против N+1.
- `config/routes.rb` — `resources :tags`, плюс nested `resources :tags, only: %i[create destroy], controller: 'task_tags'` под `tasks`.
- `db/seeds.rb` — создание трёх системных тегов.
- `spec/factories/tags.rb` — sequence + Faker.
- `spec/swagger_helper.rb` — компоненты `Tag`, `TagCollection`, `TagResource`, `TagInput`, `AttachTagInput`. У `TaskResource` добавлено поле `relationships.tags`, у `Task`/`TaskCollection` — `included` массив.
- `spec/requests/api/v1/tags_spec.rb` — 11 тестов (CRUD тегов + protection системных).
- `spec/requests/api/v1/task_tags_spec.rb` — 5 тестов (attach/detach).

---

## Шаг 3. Фильтрация задач по тегам

### Обсуждали
- По чему фильтровать: по `id`, `title`, оба варианта.
- Семантика для нескольких тегов: OR (хоть один из) или AND (все из).

### Решения
- **Оба варианта** — `q[tags_id_in][]=N` и `q[tags_title_in][]=name`. Кода почти столько же.
- **OR-семантика** через стандартный ransack `_in`. AND отложили — добавим, если возникнет реальный запрос.
- **`.distinct`** в `index` — JOIN с tags может дублировать строки задачи.

### Реализовано
- `app/models/task.rb` — `ransackable_associations = %w[tags]`.
- `app/models/tag.rb` — `ransackable_attributes = %w[id title]`.
- `app/controllers/api/v1/tasks_controller.rb` — в `index` добавлен `.distinct`.
- `spec/requests/api/v1/tasks_spec.rb` — задокументированы query-параметры `q[tags_id_in][]` и `q[tags_title_in][]`.

---

## Шаг 4. Периодичность задач (спроектировано, реализация завтра)

### Требования (из ТЗ)

Поддержать четыре типа периодичности:
- **Ежедневные** — каждый N-й день.
- **Ежемесячные** — определённое число месяца (1–31).
- **На конкретные даты** — задачи создаются только в указанные дни.
- **Чётные/нечётные дни месяца** — только на чётные либо только на нечётные числа.

### Обсуждали

- **Подход к моделированию.** Три варианта: (А) шаблон + материализованные дочерние задачи, (Б) виртуальные повторения с расчётом на лету, (В) гибрид. Проиграли все три по критериям независимости статусов задач, лёгкости фильтров, сложности кода.
- **Background-job стек:** Sidekiq + Redis vs Solid Queue / GoodJob (PostgreSQL-only).
- **Хранение параметров повторения:** отдельные nullable-колонки + enum vs jsonb-config vs STI.
- **Структура схемы:** одна таблица `tasks` с nullable-колонками для повторения vs отдельная `task_templates`. Соблазн упростить через одну таблицу, но это размывает семантику и создаёт риск «отметил выполненной всю серию случайно».
- **API surface для шаблонов:** полноценный CRUD на `TaskTemplate` (`/api/v1/task_templates`) vs шаблон как внутренняя деталь, доступная только через `POST /api/v1/tasks` и команду «отменить серию».
- **Отмена серии:** отдельный контроллер `TaskTemplatesController` с `destroy` vs member-action на `Task` (`DELETE /api/v1/tasks/:id/recurrence`).
- **Поведение при «отмене»:** только soft-delete шаблона vs дополнительная очистка будущих pending-задач.
- **Edit шаблона:** поддерживать ли `PATCH` на шаблон, и если да — пропагировать ли изменения на уже созданных детей.
- **Тэги на шаблоне:** есть ли смысл, и копировать ли при материализации.
- **Материализация specific_dates:** все даты сразу или по окнам.
- **Время задачи:** дефолтное `time_of_day = 09:00` vs обязательное явное от клиента.
- **Окно от создания:** включать ли «сегодня», если время уже прошло.
- **Дедуп:** только app-level (`unless exists?`) vs DB-level partial unique index.
- **Архитектура контроллеров:** толстый контроллер с логикой vs тонкий контроллер + сервисы под `app/services/`.
- **Связь тегов:** отдельная join-таблица `task_template_tags` vs polymorphic `taggings`.

### Решения

- **Подход (В) — гибрид:** шаблон с правилом + материализованные дочерние `Task` (обычные записи с FK `task_template_id`). Окно материализации — до конца текущего месяца. Sidekiq-cron 1-го числа каждого месяца достраивает следующий месяц.
- **Background-стек — Sidekiq + Redis** (несмотря на необходимость дополнительного сервиса; обоснование пользователя: «слишком распространённая связка»). Redis установлен локально в WSL, без Docker.
- **Хранение — отдельные колонки + enum** `recurrence_type`. Колонки: `interval` (для daily), `day_of_month` (для monthly), `specific_datetimes timestamp[]` (для specific_dates), `time_of_day time`, `ends_at date nullable`, `active boolean default true`.
- **Отдельная модель `TaskTemplate`** — иначе nullable-каша в `tasks` и риск перепутать «правила» и «инстансы». Чистое разделение ролей.
- **API создания через `POST /api/v1/tasks`** — нет `TaskTemplatesController.create`. Сервис `Tasks::Creator` диспатчит: если в payload есть recurrence-поля → создание `TaskTemplate` + материализация; иначе → одиночная `Task.create!`.
- **Отмена серии — `DELETE /api/v1/tasks/:id/recurrence`** (member-action на Task). Action: soft-delete шаблона (`active = false`) + удаление всех будущих `pending` задач этой серии (включая ту, на которой стоит пользователь). Идемпотентно — повторный вызов на уже неактивной серии возвращает 204 без ошибки.
- **Edit шаблона не делаем.** Никакого `PATCH /api/v1/task_templates/:id`. Если правило надо изменить — отменить серию, создать новую. Это избавляет от хирургии «переписывать или нет уже созданных детей».
- **Теги на шаблоне есть** — отдельная join-таблица `task_template_tags` (не polymorphic, для консистентности с уже выбранным паттерном явных join-моделей и сохранения FK constraints). При материализации каждый тег копируется в `task_tags` для созданной `Task`.
- **`specific_dates` материализуется сразу всеми датами при создании.** Sidekiq-джоб обходит только daily/monthly/even/odd (для specific_dates он бесполезен — даты конечны и известны).
- **`time_of_day` обязательное, без дефолта.** Клиент всегда присылает явно. Поле — отдельное `time_of_day: "14:30"`. Опционально только для типа `specific_dates` (там время живёт в datetime'ах самих дат).
- **Окно от создания:** «сегодня» включаем, только если `Time.current < today + time_of_day`. Иначе стартуем с завтра. Логика: `pending`-задача со временем в прошлом, созданная пользователем только что, выглядит абсурдно.
- **Дедуп — двойной:** app-level `unless template.tasks.where(scheduled_at: target).exists?` плюс DB partial unique index `(task_template_id, scheduled_at) WHERE task_template_id IS NOT NULL`. Здесь не экономим — Sidekiq-ретраи реальный источник гонок, корректность важнее эстетики «лишних индексов».
- **Архитектура — тонкие контроллеры, сервисы под `app/services/`** (правило сохранено в memory). Любая логика обработки объектов — в сервисах. Контроллер только вызывает сервис и рендерит.

### План реализации (на завтра)

10 шагов, в порядке:

1. **Инфра.** Gemfile (`sidekiq`, `sidekiq-cron`), `config/initializers/sidekiq.rb`, `config/sidekiq.yml`, `config/schedule.yml`, `mount Sidekiq::Web` в роутах. `config.active_job.queue_adapter = :sidekiq`.
2. **Миграции.** `create_task_templates`, `create_task_template_tags`, `add_task_template_id_to_tasks`, `add_partial_unique_index_to_tasks`.
3. **Модели.** `TaskTemplate` (enum, условные валидации по типу, связи с tasks/tags, скоупы), `TaskTemplateTag` (join), обновить `Task` (`belongs_to :task_template, optional: true`, кастомное `Task::NotInRecurringSeries`).
4. **Сервисы.** `Tasks::Creator` (диспатч), `TaskTemplates::Creator` (создание + материализация транзакционно), `TaskTemplates::Materializer` (генерация дат + дедуп + копирование тегов), `TaskTemplates::Recurrence::*Strategy` (5 классов на типы повторения, метод `occurrences_in(range)`), `Tasks::RecurrenceCanceller` (soft-delete + чистка будущих pending).
5. **Job.** `MonthlyMaterializationJob` — раз в месяц 1-го числа в 00:00 для каждого активного шаблона типов кроме specific_dates вызывает `Materializer` на следующий календарный месяц.
6. **Роуты + контроллер + helper.** `delete :recurrence, on: :member`, `TasksController#create` переписать на `Tasks::Creator.call`, новый member-action `cancel_recurrence`. В `ApiErrorHelper` ветка для `Task::NotInRecurringSeries → 422`.
7. **Сериализатор.** В `TaskSerializer` добавить `task_template_id` (фронт по нему понимает «эта задача из серии», знает рисовать кнопку «отменить серию»).
8. **Фабрика.** `task_template` с трейтами `:daily/:monthly/:even_days/:odd_days/:specific_dates`.
9. **Тесты.** Юниты на стратегии (плотная логика), материализатор (дедуп, копирование тегов), `Tasks::Creator` (диспатч), `Tasks::RecurrenceCanceller` (soft-delete + чистка, идемпотентность). Request-spec'ы: создание каждого из 4 типов через `POST /tasks` (201), `DELETE /tasks/:id/recurrence` (204 success, 422 not in series, идемпотентность).
10. **Swagger.** Расширить `TaskInput` recurrence-полями (опциональные), описать `DELETE /api/v1/tasks/:id/recurrence`.

### Дефолты, которые приму без отдельного обсуждения

- **Anchor для `daily, interval: N`** — отсчёт от даты создания шаблона. Например, создан 9 мая, `interval: 3` → 9, 12, 15, 18 (если 9 мая отбрасывается по правилу 5г — стартуем с 12).
- **`monthly, day_of_month: 31` в феврале** — пропускаем, не материализуем.
- **`task_template_id` в TaskSerializer** — отдаём как `string` (JSON:API id-конвенция) или `null`.

Сегодня остановились на этом. Завтра — Шаг 1 (инфра Sidekiq).
