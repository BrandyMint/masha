# План имплементации: Команда `/owner` для Telegram бота Masha

**Автор:** Технический аналитик
**Дата создания:** 2025-10-22
**Версия:** 1.0
**Основано на спецификации:** owner_command_specification.md

## 1. Обзор плана

Данный план описывает пошаговую имплементацию команды `/owner` для управления владельцами проектов. План разбит на логические этапы с учетом существующей архитектуры проекта.

## 2. Анализ существующего кода

### 2.1. Изученные компоненты:
- `app/controllers/telegram/commands/base_command.rb` - базовый класс команд
- `app/controllers/telegram/commands/users_command.rb` - пример команды для разработчика
- `app/controllers/concerns/telegram_helpers.rb` - общие хелперы, включая `developer?`
- Существующие команды: `adduser_command.rb`, `rename_command.rb`, `hours_command.rb`

### 2.2. Ключевые паттерны:
- Все команды наследуются от `BaseCommand`
- Использование `respond_with :message, text: ..., parse_mode: :Markdown`
- Форматирование через `code()` и `multiline()` хелперы
- Проверка прав через `developer?` метод
- Поиск проектов через `find_project()` метод

## 3. Этапы имплементации

### Этап 1: Создание базовой структуры команды

#### Задача 1.1: Создать класс OwnerCommand
**Файл:** `app/controllers/telegram/commands/owner_command.rb`

```ruby
# frozen_string_literal: true

module Telegram
  module Commands
    class OwnerCommand < BaseCommand
      def call(*args)
        # Проверка прав доступа
        unless developer?
          respond_with :message, text: 'Эта команда доступна только разработчику системы'
          return
        end

        # Обработка различных режимов команды
        case args.size
        when 0
          show_all_projects
        when 1
          handle_single_argument(args.first)
        when 2
          change_project_owner(args[0], args[1])
        else
          show_usage_help
        end
      end

      private

      def show_all_projects
        # Реализация вывода всех проектов
      end

      def handle_single_argument(arg)
        # Реализация фильтрации (active, archived, orphaned, search)
      end

      def change_project_owner(project_slug, new_owner_identifier)
        # Реализация смены владельца
      end

      def show_usage_help
        # Реализация справки по использованию
      end
    end
  end
end
```

#### Задача 1.2: Добавить команду в роутинг
**Файл:** `config/routes.rb`

Проверить существующий механизм обработки команд и добавить `/owner` в список.

### Этап 2: Имплементация основной функциональности

#### Задача 2.1: Метод `show_all_projects`
```ruby
def show_all_projects
  projects = Project.includes(:memberships, :user)
                   .order(:name)

  if projects.empty?
    respond_with :message, text: 'В системе нет проектов'
    return
  end

  table_data = build_projects_table(projects)
  table = Terminal::Table.new(headings: ['Проект', 'Slug', 'Владелец', 'Статус'], rows: table_data)

  respond_with :message, text: code(table.to_s), parse_mode: :Markdown
end

def build_projects_table(projects)
  projects.map do |project|
    owner = find_project_owner(project)
    status = project.archived? ? 'Архивный' : 'Активный'

    [
      truncate_string(project.name, 30),
      project.slug,
      owner,
      status
    ]
  end
end

def find_project_owner(project)
  owner_membership = project.memberships.find_by(role: 'owner')
  return 'Нет владельца' unless owner_membership

  user = owner_membership.user
  format_user_info_compact(user)
end

def format_user_info_compact(user)
  parts = []
  parts << user.name if user.name.present?
  parts << user.email if user.email.present?
  if user.telegram_user&.username
    parts << "@#{user.telegram_user.username}"
  end
  parts.empty? ? 'ID: ' + user.id.to_s : parts.join(' ')
end
```

#### Задача 2.2: Метод `handle_single_argument`
```ruby
def handle_single_argument(arg)
  case arg.downcase
  when 'active'
    show_filtered_projects(archived: false)
  when 'archived'
    show_filtered_projects(archived: true)
  when 'orphaned'
    show_orphaned_projects
  when 'search'
    respond_with :message, text: 'Использование: /owner search {текст_поиска}'
  else
    if arg.start_with?('search ')
      search_term = arg[7..-1] # Удаляем 'search '
      search_projects(search_term)
    else
      respond_with :message, text: "Неизвестный фильтр '#{arg}'. Доступные фильтры: active, archived, orphaned, search {текст}"
    end
  end
end

def show_filtered_projects(archived:)
  projects = Project.includes(:memberships, :user)
                   .where(archived: archived)
                   .order(:name)

  status_text = archived ? 'архивных' : 'активных'
  if projects.empty?
    respond_with :message, text: "В системе нет #{status_text} проектов"
    return
  end

  table_data = build_projects_table(projects)
  table = Terminal::Table.new(headings: ['Проект', 'Slug', 'Владелец'], rows: table_data)

  respond_with :message, text: code("#{status_text.capitalize} проекты:\n#{table}"), parse_mode: :Markdown
end

def show_orphaned_projects
  ownerless_projects = Project.left_joins(:memberships)
                            .where(memberships: { role: 'owner' })
                            .where.not(projects: { id: nil })
                            .includes(:memberships)
                            .order(:name)

  if ownerless_projects.empty?
    respond_with :message, text: 'Все проекты имеют владельцев'
    return
  end

  project_slugs = ownerless_projects.map(&:slug).join(', ')
  respond_with :message, text: "Проекты без владельца (#{ownerless_projects.size}):\n#{project_slugs}"
end

def search_projects(search_term)
  projects = Project.includes(:memberships, :user)
                   .where('name ILIKE ? OR slug ILIKE ?', "%#{search_term}%", "%#{search_term}%")
                   .order(:name)

  if projects.empty?
    respond_with :message, text: "Проекты, содержащие '#{search_term}', не найдены"
    return
  end

  table_data = build_projects_table(projects)
  table = Terminal::Table.new(headings: ['Проект', 'Slug', 'Владелец'], rows: table_data)

  respond_with :message, text: code("Результаты поиска '#{search_term}':\n#{table}"), parse_mode: :Markdown
end
```

### Этап 3: Имплементация смены владельца

#### Задача 3.1: Метод `change_project_owner`
```ruby
def change_project_owner(project_slug, new_owner_identifier)
  # Валидация и поиск проекта
  project = Project.find_by(slug: project_slug)
  unless project
    available_projects = Project.pluck(:slug).join(', ')
    respond_with :message, text: "Проект '#{project_slug}' не найден. Доступные проекты: #{available_projects}"
    return
  end

  # Поиск нового владельца
  new_owner = find_user_by_identifier(new_owner_identifier)
  unless new_owner
    respond_with :message, text: "Пользователь '#{new_owner_identifier}' не найден в системе. Используйте email или Telegram username (@username)"
    return
  end

  # Проверка, что пользователь не является текущим владельцем
  current_owner = find_current_project_owner(project)
  if current_owner == new_owner
    respond_with :message, text: "Пользователь '#{format_user_info_compact(new_owner)}' уже является владельцем проекта '#{project.name}'"
    return
  end

  # Выполнение смены владельца в транзакции
  ActiveRecord::Base.transaction do
    # Удалить старую роль owner, если она существует
    project.memberships.where(role: 'owner').destroy_all

    # Создать новую membership с ролью owner
    project.memberships.create!(user: new_owner, role: 'owner')

    # Присвоить старому владельцу роль watcher, если он существовал
    if current_owner
      existing_membership = current_owner.membership_of(project)
      if existing_membership
        existing_membership.update!(role: 'watcher')
      else
        project.memberships.create!(user: current_owner, role: 'watcher')
      end
    end

    # Логирование операции
    Rails.logger.info "Project owner changed: #{project.slug} - old: #{current_owner&.email} - new: #{new_owner.email}"
  end

  # Формирование ответа
  old_owner_info = current_owner ? format_user_info_compact(current_owner) : 'Нет владельца'
  new_owner_info = format_user_info_compact(new_owner)

  response_text = <<~TEXT
    ✅ Владелец проекта '#{project.name}' изменен!
    🔸 Старый владелец: #{old_owner_info}
    🔸 Новый владелец: #{new_owner_info}
    #{current_owner ? "📝 Старый владелец теперь имеет роль 'watcher'" : ''}
  TEXT

  respond_with :message, text: response_text
rescue StandardError => e
  Rails.logger.error "Error changing project owner: #{e.message}"
  respond_with :message, text: "❌ Ошибка при смене владельца: #{e.message}"
end
```

#### Задача 3.2: Вспомогательные методы
```ruby
def find_current_project_owner(project)
  owner_membership = project.memberships.find_by(role: 'owner')
  owner_membership&.user
end

def find_user_by_identifier(identifier)
  # Попытка найти по email
  return User.find_by(email: identifier) if identifier.include?('@')

  # Попытка найти по telegram username
  clean_identifier = identifier.delete_prefix('@')
  telegram_user = TelegramUser.find_by(username: clean_identifier)
  return telegram_user.user if telegram_user

  # Попытка найти по ID
  return User.find_by(id: identifier.to_i) if identifier.match?(/\A\d+\z/)

  # Попытка найти по имени
  User.find_by(name: identifier)
end

def truncate_string(string, max_length)
  return string if string.length <= max_length
  "#{string[0...max_length - 3]}..."
end
```

### Этап 4: Имплементация справки

#### Задача 4.1: Метод `show_usage_help`
```ruby
def show_usage_help
  help_text = <<~HELP
    📋 *Команда /owner - управление владельцами проектов*

    *Просмотр владельцев:*
    `/owner` - показать все проекты и их владельцев
    `/owner active` - только активные проекты
    `/owner archived` - только архивные проекты
    `/owner orphaned` - проекты без владельцев
    `/owner search {текст}` - поиск проектов

    *Смена владельца:*
    `/owner {project_slug} {email|@username|user_id}`

    *Примеры:*
    `/owner my-project user@example.com`
    `/owner website @username`
    `/owner app 123`

    ⚠️ *Доступно только разработчику системы*
  HELP

  respond_with :message, text: help_text, parse_mode: :Markdown
end
```

### Этап 5: Тестирование

#### Задача 5.1: Создать RSpec тесты
**Файл:** `spec/controllers/telegram/commands/owner_command_spec.rb`

```ruby
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Telegram::Commands::OwnerCommand, type: :controller do
  let(:controller) { double('controller') }
  let(:command) { described_class.new(controller) }
  let(:developer_telegram_id) { ApplicationConfig.developer_telegram_id }
  let(:developer) { create(:user, telegram_user: create(:telegram_user, id: developer_telegram_id)) }

  before do
    allow(controller).to receive(:developer?).and_return(true)
    allow(controller).to receive(:respond_with)
  end

  describe '#call' do
    context 'when user is not developer' do
      before do
        allow(controller).to receive(:developer?).and_return(false)
      end

      it 'returns access denied message' do
        expect(controller).to receive(:respond_with).with(:message, text: 'Эта команда доступна только разработчику системы')
        command.call
      end
    end

    context 'when showing all projects' do
      let!(:project1) { create(:project, name: 'Project 1', slug: 'project-1') }
      let!(:project2) { create(:project, name: 'Project 2', slug: 'project-2', archived: true) }
      let!(:owner) { create(:user) }

      before do
        project1.memberships.create!(user: owner, role: 'owner')
      end

      it 'shows projects with owners in table format' do
        expect(controller).to receive(:respond_with) do |type, options|
          expect(type).to eq(:message)
          expect(options[:parse_mode]).to eq(:Markdown)
          expect(options[:text]).to include('Project 1')
          expect(options[:text]).to include('project-1')
        end

        command.call
      end

      it 'shows orphaned projects correctly' do
        expect(controller).to receive(:respond_with) do |type, options|
          expect(options[:text]).to include('Нет владельца')
        end

        command.call
      end
    end

    context 'when filtering projects' do
      let!(:active_project) { create(:project, archived: false) }
      let!(:archived_project) { create(:project, archived: true) }

      it 'filters active projects' do
        expect(controller).to receive(:respond_with) do |type, options|
          expect(options[:text]).to include('Активные проекты')
        end

        command.call('active')
      end

      it 'filters archived projects' do
        expect(controller).to receive(:respond_with) do |type, options|
          expect(options[:text]).to include('Архивные проекты')
        end

        command.call('archived')
      end
    end

    context 'when changing project owner' do
      let!(:project) { create(:project, slug: 'test-project') }
      let!(:old_owner) { create(:user, email: 'old@example.com') }
      let!(:new_owner) { create(:user, email: 'new@example.com') }

      before do
        project.memberships.create!(user: old_owner, role: 'owner')
      end

      it 'changes owner successfully' do
        expect(controller).to receive(:respond_with) do |type, options|
          expect(options[:text]).to include('Владелец проекта')
          expect(options[:text]).to include('new@example.com')
          expect(options[:text]).to include('watcher')
        end

        command.call('test-project', 'new@example.com')

        project.reload
        expect(project.memberships.find_by(role: 'owner').user).to eq(new_owner)
        expect(project.memberships.find_by(role: 'watcher').user).to eq(old_owner)
      end

      it 'handles non-existent project' do
        expect(controller).to receive(:respond_with) do |type, options|
          expect(options[:text]).to include('не найден')
        end

        command.call('non-existent', 'new@example.com')
      end

      it 'handles non-existent user' do
        expect(controller).to receive(:respond_with) do |type, options|
          expect(options[:text]).to include('не найден в системе')
        end

        command.call('test-project', 'nonexistent@example.com')
      end
    end
  end

  describe 'private methods' do
    let(:user) { create(:user, name: 'Test User', email: 'test@example.com') }
    let(:telegram_user) { create(:telegram_user, user: user, username: 'testuser') }

    describe '#find_user_by_identifier' do
      before do
        user.update!(telegram_user: telegram_user)
        command.instance_variable_set(:@controller, controller)
      end

      it 'finds user by email' do
        found_user = command.send(:find_user_by_identifier, 'test@example.com')
        expect(found_user).to eq(user)
      end

      it 'finds user by telegram username with @' do
        found_user = command.send(:find_user_by_identifier, '@testuser')
        expect(found_user).to eq(user)
      end

      it 'finds user by telegram username without @' do
        found_user = command.send(:find_user_by_identifier, 'testuser')
        expect(found_user).to eq(user)
      end

      it 'finds user by ID' do
        found_user = command.send(:find_user_by_identifier, user.id.to_s)
        expect(found_user).to eq(user)
      end

      it 'finds user by name' do
        found_user = command.send(:find_user_by_identifier, 'Test User')
        expect(found_user).to eq(user)
      end
    end
  end
end
```

#### Задача 5.2: Создать фабрики для тестов
```ruby
# В файле spec/factories/users.rb (дополнение)
FactoryBot.define do
  factory :telegram_user do
    sequence(:id) { |n| 1000 + n }
    sequence(:username) { |n| "user#{n}" }
    sequence(:first_name) { |n| "User#{n}" }
  end
end
```

### Этап 6: Интеграция и документация

#### Задача 6.1: Обновить справку бота
**Файл:** `app/controllers/concerns/telegram_helpers.rb`

Добавить `/owner` в `help_message` метод:

```ruby
def help_message
  commands = [
    # ... существующие команды ...
    '/summary {week|month}- Суммарный отчёт за период',
    '/hours [project_slug] - Все часы за последние 3 месяца',
    '',
    'Быстрое добавление времени:',
    '{hours} {project_slug} [description] - например: "2.5 myproject работал над фичей"',
    '{project_slug} {hours} [description] - например: "myproject 2.5 работал над фичей"'
  ]

  # Add developer commands if user is developer
  if developer?
    commands << '# Только для разработчика'
    commands << '/users - Список всех пользователей системы (только для разработчика)'
    commands << '/merge {email} {telegram_username} - Объединить аккаунты (только для разработчика)'
    commands << '/owner - Управление владельцами проектов (только для разработчика)'
  end

  multiline(commands)
end
```

#### Задача 6.2: Создать документацию API
**Файл:** `docs/telegram_commands.md` (если существует) или обновить README

### Этап 7: Рефакторинг и оптимизация

#### Задача 7.1: Оптимизация запросов
- Добавить proper includes для избежания N+1 запросов
- Использовать кэширование для частых запросов
- Пагинация для больших списков проектов

#### Задача 7.2: Улучшение форматирования
- Добавить цветовое выделение (если возможно)
- Улучшить форматирование таблиц
- Добавить эмодзи для лучшей читаемости

## 4. Порядок выполнения

1. **Подготовка (1 день)**
   - Создать базовый класс OwnerCommand
   - Добавить в роутинг

2. **Основная функциональность (2-3 дня)**
   - Реализовать показ всех проектов
   - Реализовать фильтрацию проектов
   - Реализовать смену владельца

3. **Тестирование (2 дня)**
   - Написать RSpec тесты
   - Протестировать ручное тестирование

4. **Интеграция и доработка (1 день)**
   - Обновить справку
   - Оптимизировать код
   - Провести финальное тестирование

## 5. Критерии готовности

- [ ] Все функциональные требования реализованы
- [ ] Все тесты проходят (покрытие > 90%)
- [ ] Код соответствует RuboCop стандартам
- [ ] Ручное тестирование успешно
- [ ] Документация обновлена
- [ ] Команда добавлена в справку бота

## 6. Риски и митигация

**Риски:**
- Сложность с поиском пользователей по разным идентификаторам
- Проблемы с транзакционной целостностью
- Производительность при большом количестве проектов

**Митигация:**
- Тщательное тестирование всех сценариев поиска
- Использование транзакций и proper error handling
- Оптимизация запросов и pagination при необходимости