# План реализации: Удаление поля `name` из модели Project

**Дата:** 2025-11-16
**Спецификация:** `remove_project_name_field_specification.md`

---

## Общая стратегия

1. ✅ **Подготовка**: анализ кода, создание спецификации
2. 🔄 **Реализация**: последовательное изменение компонентов
3. ⏳ **Тестирование**: проверка всех изменений
4. ⏳ **Миграция БД**: финальное удаление колонки

**Важно:** Изменения идут снизу вверх (модель → services → commands → views → tests)

---

## Этап 1: Обновление fixtures (spec/fixtures/projects.yml)

**Цель:** Подготовить тестовые данные к новой структуре

**Файл:** `spec/fixtures/projects.yml`

**Действия:**
```yaml
# До:
work_project:
  name: Work Project
  slug: work-project
  active: true

# После:
work_project:
  slug: work-project
  active: true
```

**Изменения:**
- Удалить поле `name:` из всех 50+ проектов
- Оставить только: `slug`, `active`, `created_at`, `updated_at`, `client` (если есть)

**Проверка:**
```bash
grep "name:" spec/fixtures/projects.yml  # Должно вернуть 0 результатов
```

---

## Этап 2: Модель Project (app/models/project.rb)

**Файл:** `app/models/project.rb`

### Изменение 1: friendly_id
```ruby
# До:
friendly_id :name, use: :slugged

# После:
friendly_id :slug, use: :slugged
```

### Изменение 2: Удалить валидацию name
```ruby
# Удалить:
validates :name, presence: true, uniqueness: true
```

### Изменение 3: Scope ordered
```ruby
# До:
scope :ordered, -> { order(:name) }

# После:
scope :ordered, -> { order(:slug) }
```

### Изменение 4: Метод should_generate_new_friendly_id?
```ruby
# Удалить метод (строки 31-33):
def should_generate_new_friendly_id?
  name_changed?
end
```

### Изменение 5: Метод generate_unique_slug
```ruby
# До:
def self.generate_unique_slug(base_name)
  base_slug = Russian.translit(base_name.to_s)
                      .squish
                      .parameterize
                      .truncate(15, omission: '')
  # ...
end

# После:
def self.generate_unique_slug(base_slug)
  # Принимаем slug напрямую, без транслитерации
  normalized_slug = base_slug.to_s
                             .downcase
                             .strip
                             .truncate(15, omission: '')

  slug = normalized_slug
  counter = 1

  while Project.exists?(slug: slug)
    suffix = "-#{counter}"
    max_length = 15 - suffix.length
    slug = "#{normalized_slug.truncate(max_length, omission: '')}#{suffix}"
    counter += 1
  end

  slug
end
```

### Изменение 6: Callback before_validation
```ruby
# Удалить или упростить:
before_validation :ensure_slug

def ensure_slug
  # До: генерация slug из name
  # self.slug = Russian.translit(name.to_s).squish.parameterize if slug.blank?

  # После: slug должен быть задан явно, автогенерация не нужна
  # Метод можно удалить полностью
end
```

**Проверка:**
```bash
bundle exec rubocop app/models/project.rb
bundle exec ruby -c app/models/project.rb
```

---

## Этап 3: Commands (app/commands/)

### 3.1 ProjectsCommand (app/commands/projects_command.rb)

**Основные изменения:**

#### А) Удалить context methods для переименования title
```ruby
# Удалить из provides_context_methods:
:awaiting_rename_title
:awaiting_rename_both
:awaiting_rename_both_step_2

# Удалить константы:
CONTEXT_AWAITING_RENAME_TITLE
CONTEXT_AWAITING_RENAME_BOTH
CONTEXT_AWAITING_RENAME_BOTH_STEP_2
```

#### Б) Удалить callback query methods
```ruby
# Удалить методы:
def projects_rename_title_callback_query(data = nil)
def projects_rename_both_callback_query(data = nil)
def projects_rename_use_suggested_callback_query(data = nil)
```

#### В) Метод awaiting_project_name
```ruby
# До:
def awaiting_project_name(*name_parts)
  name = name_parts.join(' ').strip
  # ...
  slug = Project.generate_unique_slug(name)
  project = Project.new(name: name, slug: slug)
  # ...
end

# После:
def awaiting_project_name(*slug_parts)
  slug = slug_parts.join('-').strip.downcase
  return respond_with :message, text: 'Slug не может быть пустым' if slug.blank?
  return respond_with :message, text: t('commands.projects.rename.slug_invalid') if invalid_slug?(slug)

  # Проверка уникальности
  if Project.exists?(slug: slug)
    return respond_with :message, text: t('commands.projects.rename.slug_taken', slug: slug)
  end

  project = Project.new(slug: slug)
  if project.save
    Membership.create!(user: current_user, project: project, role: :owner)
    respond_with :message, text: t('commands.projects.create.success', slug: project.slug)
    show_projects_list
  else
    respond_with :message, text: t('commands.projects.create.error', reason: project.errors.full_messages.join(', '))
  end
end
```

#### Г) Удалить методы переименования title и both
```ruby
# Удалить методы полностью:
def awaiting_rename_title(*title_parts)
def awaiting_rename_both(*title_parts)
def awaiting_rename_both_step_2(*slug_parts)
def start_rename_title(slug)
def start_rename_both(slug)
def use_suggested_slug(slug, suggested_slug)
def update_project_both(project, new_name, new_slug)
```

#### Д) Метод show_rename_menu - упростить
```ruby
# До:
def show_rename_menu(slug)
  # ...
  buttons = [
    [{ text: t('commands.projects.rename.title_button'), ... }],
    [{ text: t('commands.projects.rename.slug_button'), ... }],
    [{ text: t('commands.projects.rename.both_button'), ... }],
    # ...
  ]
end

# После:
def show_rename_menu(slug)
  project = current_user.projects.find_by(slug: slug)
  return show_projects_list unless project&.can_be_managed_by?(current_user)

  # Сразу запускаем переименование slug
  start_rename_slug(slug)
end
```

#### Е) Метод show_project_menu - заменить name на slug
```ruby
# До:
menu_text = t('commands.projects.menu.title',
              name: project.name,
              slug: project.slug,
              client: client_text)

# После:
menu_text = t('commands.projects.menu.title',
              slug: project.slug,
              client: client_text)
```

#### Ж) Метод create_project_legacy
```ruby
# До:
project = Project.new(name: slug, slug: slug)

# После:
project = Project.new(slug: slug)
```

#### З) Метод awaiting_delete_confirm
```ruby
# До:
if confirmation != project.name

# После:
if confirmation != project.slug
```

### 3.2 AddCommand (app/commands/add_command.rb)

**Строки 41, 73:**
```ruby
# До:
respond_with :message, text: "Отметили в #{project.name} #{hours} часов"

# После:
respond_with :message, text: "Отметили в #{project.slug} #{hours} часов"
```

### 3.3 EditCommand (app/commands/edit_command.rb)

**Строка 195:**
```ruby
# До:
"Проект: #{time_shift.project.name}\n"

# После:
"Проект: #{time_shift.project.slug}\n"
```

**Строка 220:**
```ruby
# До:
text = "Выберите новый проект (текущий: #{time_shift.project.name}):"

# После:
text = "Выберите новый проект (текущий: #{time_shift.project.slug}):"
```

**Строка 284:**
```ruby
# До:
["Проект: #{time_shift.project.name} → #{new_project.name}"]

# После:
["Проект: #{time_shift.project.slug} → #{new_project.slug}"]
```

### 3.4 UsersCommand (app/commands/users_command.rb)

**Строка 98:**
```ruby
# До:
respond_with :message, text: "В проекте '#{project.name}' нет пользователей"

# После:
respond_with :message, text: "В проекте '#{project.slug}' нет пользователей"
```

**Строка 109:**
```ruby
# До:
respond_with :message, text: "Пользователи проекта '#{project.name}':\n\n#{users_text}"

# После:
respond_with :message, text: "Пользователи проекта '#{project.slug}':\n\n#{users_text}"
```

**Строка 177:**
```ruby
# До:
edit_message :text, text: "Проект: #{project.name}\nТеперь введите никнейм..."

# После:
edit_message :text, text: "Проект: #{project.slug}\nТеперь введите никнейм..."
```

### 3.5 RateCommand (app/commands/rate_command.rb)

**Строки 66, 150, 158, 195, 204:**
```ruby
# Заменить все вхождения project.name на project.slug
# Использовать глобальную замену в редакторе
```

### 3.6 ClientsCommand (app/commands/clients_command.rb)

**Строки 345, 386:**
```ruby
# До:
text += "• #{project.name} (#{project.slug})\n"

# После:
text += "• #{project.slug}\n"
```

---

## Этап 4: Services

### 4.1 TimeShiftOperationsService

**Файл:** `app/services/telegram/time_shift_operations_service.rb`

**Строка 36:**
```ruby
# До:
message_parts = ["✅ Отметили #{hours_float}ч в проекте #{project.name}"]

# После:
message_parts = ["✅ Отметили #{hours_float}ч в проекте #{project.slug}"]
```

---

## Этап 5: Jobs и Mailers

### 5.1 ProjectMemberNotificationJob

**Файл:** `app/jobs/project_member_notification_job.rb`

**Строка 45:**
```ruby
# До:
message = "👥 В проект \"#{project.name}\" добавлен новый участник:\n"

# После:
message = "👥 В проект \"#{project.slug}\" добавлен новый участник:\n"
```

### 5.2 InviteMailer

**Файл:** `app/mailers/invite_mailer.rb`

**Строка 7:**
```ruby
# До:
mail(to: @invite.email, subject: t('new_invite', project: @invite.project.name))

# После:
mail(to: @invite.email, subject: t('new_invite', project: @invite.project.slug))
```

### 5.3 TelegramUser model

**Файл:** `app/models/telegram_user.rb`

**Строка 66:**
```ruby
# До:
message: "🎉 Вы были добавлены в проект '#{invite.project.name}' с ролью..."

# После:
message: "🎉 Вы были добавлены в проект '#{invite.project.slug}' с ролью..."
```

---

## Этап 6: Views

### 6.1 memberships/index.html.haml

**Файл:** `app/views/memberships/index.html.haml`

**Строки 3-5:**
```haml
-# До:
%h1
  Проект '#{@project.name}'
  - unless @project.slug == @project.name
    %code.text-muted= @project.slug

-# После:
%h1
  Проект
  %code.text-muted= @project.slug
```

### 6.2 projects/_projects.html.haml

**Файл:** `app/views/projects/_projects.html.haml`

**Строки 13-15:**
```haml
-# До:
%th
  = link_to project.name, project_memberships_url(project.id)
  - unless project.slug == project.name
    %code.text-muted= project.slug

-# После:
%th
  = link_to project.slug, project_memberships_url(project.id)
```

### 6.3 invite_mailer views

**Файлы:**
- `app/views/invite_mailer/new_invite_email.html.haml`
- `app/views/invite_mailer/new_invite_email.text.haml`

**Заменить:**
```haml
-# До:
@invite.project.name

-# После:
@invite.project.slug
```

---

## Этап 7: I18n (config/locales/ru.yml)

**Файл:** `config/locales/ru.yml`

### Секция commands.projects.create:
```yaml
# До:
create:
  enter_name: "📝 Введите название проекта (или 'cancel' для отмены):"
  success: "✅ Создан проект '%{name}' (`%{slug}`)"

# После:
create:
  enter_name: "📝 Введите slug (идентификатор) проекта (или 'cancel' для отмены):\n\n💡 Только латиница, цифры и дефисы (макс 15 символов)\nПример: my-awesome-project"
  success: "✅ Создан проект `%{slug}`"
```

### Секция commands.projects.rename:
```yaml
# Удалить:
rename:
  title: "Переименование проекта '%{name}'"
  title_button: "📝 Переименовать название"
  both_button: "🔄 Переименовать название и slug"
  enter_title: "Введите новое название (текущее: %{current_name}):"
  success_title: "✅ Название изменено: '%{old_name}' → '%{new_name}'"
  success_both: "✅ Проект переименован:\n• Название: '%{old_name}' → '%{new_name}'\n• Slug: %{old_slug} → %{new_slug}"
  use_suggested: "✅ Использовать предложенный slug"

# Оставить и упростить:
rename:
  slug_button: "🔧 Переименовать проект"
  enter_slug: "Введите новый slug (текущий: %{current_slug}):"
  success_slug: "✅ Проект переименован: %{old_slug} → %{new_slug}"
  slug_invalid: "❌ Недопустимый slug. Используйте только латиницу, цифры и дефисы (макс 15 символов)"
  slug_taken: "❌ Slug '%{slug}' уже используется"
  cancelled: "❌ Переименование отменено"
```

### Секция commands.projects.menu:
```yaml
# До:
menu:
  title: "📋 Проект: %{name}\n🔑 Slug: `%{slug}`\n🏢 Клиент: %{client}"

# После:
menu:
  title: "📋 Проект: `%{slug}`\n🏢 Клиент: %{client}"
```

### Секция commands.projects.delete:
```yaml
# До:
delete:
  confirm_first: "⚠️ Вы действительно хотите удалить проект '%{name}'?"
  confirm_final: "⚠️ Для подтверждения введите название проекта: '%{name}'"
  name_mismatch: "❌ Название не совпадает. Удаление отменено."
  success: "✅ Проект '%{name}' удалён"

# После:
delete:
  confirm_first: "⚠️ Вы действительно хотите удалить проект `%{slug}`?"
  confirm_final: "⚠️ Для подтверждения введите slug проекта: `%{slug}`"
  name_mismatch: "❌ Slug не совпадает. Удаление отменено."
  success: "✅ Проект `%{slug}` удалён"
```

---

## Этап 8: Тесты

### 8.1 spec/controllers/telegram/webhook/projects_command_spec.rb

**Удалить тесты:**
```ruby
# Удалить context 'rename title workflow'
# Удалить context 'rename both workflow'
# Удалить все тесты с project.name
```

**Обновить тесты:**
```ruby
# Заменить все проверки:
expect(project.name).to eq('New Title')
# На:
expect(project.slug).to eq('new-title')

# Удалить проверки типа:
expect(project.name).to eq(old_name)
```

### 8.2 spec/services/reporter_spec.rb

**Строки 178, 187:**
```ruby
# До:
expect(result).to include(project.name)

# После:
expect(result).to include(project.slug)
```

### 8.3 spec/fixtures/fixture_test_spec.rb

**Строки 38:**
```ruby
# Удалить:
expect(project.name).to eq('Work Project')

# Оставить только:
expect(project.slug).to eq('work-project')
```

---

## Этап 9: Миграция базы данных

**Файл:** `db/migrate/XXXXXX_remove_name_from_projects.rb`

```ruby
class RemoveNameFromProjects < ActiveRecord::Migration[8.0]
  def up
    # Удаляем индекс
    remove_index :projects, :name if index_exists?(:projects, :name)

    # Удаляем колонку
    remove_column :projects, :name, :string
  end

  def down
    # Восстановление при rollback
    add_column :projects, :name, :string

    # Восстанавливаем данные из slug
    Project.reset_column_information
    Project.find_each do |project|
      project.update_column(:name, project.slug.titleize)
    end

    add_index :projects, :name, unique: true
  end
end
```

**Запуск:**
```bash
rails generate migration RemoveNameFromProjects
# Отредактировать созданную миграцию
rails db:migrate
```

---

## Этап 10: Финальная проверка

### Чеклист перед запуском:

**Код:**
- [ ] Все файлы обновлены согласно плану
- [ ] RuboCop проходит: `bundle exec rubocop`
- [ ] Синтаксис Ruby валиден: `bundle exec ruby -c app/models/project.rb`

**Тесты:**
- [ ] Все тесты проходят: `./bin/rspec`
- [ ] Fixtures обновлены (нет поля `name`)
- [ ] Telegram command тесты проходят

**База данных:**
- [ ] Миграция создана
- [ ] Миграция протестирована на dev БД
- [ ] Rollback миграции работает

**Локализация:**
- [ ] I18n файлы обновлены
- [ ] Нет упоминаний "название проекта"
- [ ] Все сообщения используют slug

**Функциональность:**
- [ ] Telegram бот создает проекты
- [ ] Telegram бот переименовывает проекты
- [ ] Web интерфейс отображает проекты
- [ ] Email уведомления корректны

---

## Порядок выполнения этапов

```
1. Fixtures (можно сразу)
   ↓
2. Модель Project
   ↓
3. Commands (все команды параллельно)
   ↓
4. Services
   ↓
5. Jobs & Mailers
   ↓
6. Views
   ↓
7. I18n
   ↓
8. Тесты (обновить после всего кода)
   ↓
9. Запустить все тесты
   ↓
10. Миграция БД (последняя)
```

**Время выполнения:** ~4-6 часов

---

## Команды для проверки

```bash
# Проверка что name нигде не используется
grep -r "project\.name" app/
grep -r "@project\.name" app/
grep -r "name:" spec/fixtures/projects.yml

# Проверка что все тесты проходят
./bin/rspec

# Проверка RuboCop
bundle exec rubocop

# Проверка миграции
rails db:migrate
rails db:rollback
rails db:migrate

# Проверка в rails console
rails console
> Project.first.name  # Должна быть ошибка NoMethodError
> Project.first.slug  # Должен вернуть slug
```

---

## Дополнительные заметки

1. **Не забыть**: обновить `.rubocop_todo.yaml` если появятся новые нарушения
2. **Внимание**: при rollback миграции name восстанавливается как `slug.titleize`
3. **Важно**: сначала изменить код, потом запускать миграцию БД
4. **Recommendation**: сделать backup БД перед миграцией на production

---

**Следующие шаги после реализации:**
1. Code review
2. Тестирование на staging
3. Миграция на production
4. Мониторинг метрик создания проектов
