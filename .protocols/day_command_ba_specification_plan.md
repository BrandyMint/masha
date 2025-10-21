# План имплементации: Команда `/day` для Telegram бота Masha

**Автор:** Системный архитектitect
**Дата создания:** 2025-10-21
**Версия:** 1.0
**Основание:** Бизнес-спецификация `day_command_ba_specification.md`

## 1. Обзор реализации

Команда `/day` будет реализована как новый класс `DayCommand` в существующей архитектуре Telegram бота. Реализация использует существующие паттерны команд, модели данных и механику форматирования.

## 2. Структура файлов

### Новые файлы:
```
app/controllers/telegram/commands/day_command.rb    # Основной класс команды
spec/controllers/telegram/commands/day_command_spec.rb  # RSpec тесты
```

### Модифицируемые файлы:
```
app/controllers/telegram/webhook_controller.rb      # Регистрация команды (опционально)
```

## 3. Детальная реализация

### Шаг 1: Создание класса DayCommand

**Файл:** `app/controllers/telegram/commands/day_command.rb`

```ruby
# frozen_string_literal: true

require 'terminal-table'

module Telegram
  module Commands
    class DayCommand < BaseCommand
      def call(project_key = nil, *)
        current_date = Date.current

        # Base scope for current user's time shifts for today
        time_shifts = current_user.time_shifts
                                  .includes(:project)
                                  .where(date: current_date)
                                  .order(created_at: :asc)

        # Filter by project if key provided
        if project_key.present?
          project = find_project(project_key)
          unless project
            available_projects = current_user.available_projects.alive.map(&:slug).join(', ')
            respond_with :message, text: "Не найден проект '#{project_key}'. Доступные проекты: #{available_projects}"
            return
          end

          time_shifts = time_shifts.where(project: project)
        end

        # Check if there are any time shifts
        if time_shifts.empty?
          message = if project_key.present?
                      "Нет записей времени по проекту '#{project_key}' за сегодня"
                    else
                      'За сегодня еще нет записей времени. Добавьте время с помощью команды /add'
                    end
          respond_with :message, text: message
          return
        end

        # Build and send report
        text = build_day_report(time_shifts, project_key, current_date)
        respond_with :message, text: code(text), parse_mode: :Markdown
      end

      private

      def build_day_report(time_shifts, project_key, date)
        # Group by project
        grouped_shifts = time_shifts.group_by(&:project)
        total_hours = 0

        table = Terminal::Table.new do |t|
          t << %w[Проект Часы Описание]
          t << :separator

          grouped_shifts.each do |project, shifts|
            project_total = shifts.sum(&:hours)
            total_hours += project_total

            # First row for project with total hours
            t << [project.slug, project_total, '']

            # Individual entries for this project
            shifts.each do |shift|
              description = shift.description.present? ? shift.description : '·'
              t << ['', shift.hours, description]
            end

            # Add separator between projects (except last)
            t << :separator unless project == grouped_shifts.keys.last
          end

          t << :separator
          t << ['Итого за день', total_hours, '']
        end

        table.align_column(1, :right)

        title = if project_key.present?
                  "Часы по проекту '#{project_key}' за #{date}"
                else
                  "Часы за #{date}"
                end

        "#{title}\n\n#{table}"
      end
    end
  end
end
```

### Шаг 2: Методы поиска проектов (использование существующих)

Команда будет использовать существующие методы из `BaseCommand`:
- `find_project(project_key)` - поиск проекта по ключу
- Механизм обработки ошибок и предложения доступных проектов

### Шаг 3: Тестирование

**Файл:** `spec/controllers/telegram/commands/day_command_spec.rb`

```ruby
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Telegram::Commands::DayCommand, type: :controller do
  let(:user) { create(:user) }
  let(:project1) { create(:project, slug: 'project-a') }
  let(:project2) { create(:project, slug: 'project-b') }
  let(:command) { described_class.new(context: nil, from: telegram_user(user)) }

  before do
    create(:membership, user: user, project: project1, role: :member)
    create(:membership, user: user, project: project2, role: :member)
  end

  describe '#call' do
    context 'when there are time shifts for today' do
      before do
        create(:time_shift, user: user, project: project1,
               date: Date.current, hours: 2.5, description: 'Task 1')
        create(:time_shift, user: user, project: project1,
               date: Date.current, hours: 1.5, description: 'Task 2')
        create(:time_shift, user: user, project: project2,
               date: Date.current, hours: 3.0, description: 'Task 3')
      end

      it 'returns formatted day report grouped by projects' do
        expect(command).to receive(:respond_with).with(:message, text: anything, parse_mode: :Markdown)

        command.call

        # Verify the response contains project information
        # Additional assertions can be added here
      end

      it 'calculates correct total hours' do
        allow(command).to receive(:respond_with)
        command.call

        # Total should be 7.0 hours (2.5 + 1.5 + 3.0)
        # Additional verification of total calculation
      end
    end

    context 'when filtering by specific project' do
      before do
        create(:time_shift, user: user, project: project1,
               date: Date.current, hours: 2.5, description: 'Task 1')
        create(:time_shift, user: user, project: project2,
               date: Date.current, hours: 3.0, description: 'Task 3')
      end

      it 'shows only time shifts for specified project' do
        expect(command).to receive(:respond_with).with(:message, text: anything, parse_mode: :Markdown)

        command.call('project-a')

        # Verify only project-a entries are included
      end
    end

    context 'when there are no time shifts for today' do
      it 'returns appropriate message' do
        expect(command).to receive(:respond_with).with(
          :message,
          text: 'За сегодня еще нет записей времени. Добавьте время с помощью команды /add'
        )

        command.call
      end
    end

    context 'when project is not found' do
      it 'returns error message with available projects' do
        expect(command).to receive(:respond_with).with(
          :message,
          text: /Не найден проект 'nonexistent'/
        )

        command.call('nonexistent')
      end
    end
  end

  private

  def telegram_user(user)
    OpenStruct.new(id: user.telegram_user&.telegram_id || 12345)
  end
end
```

## 4. Технические детали реализации

### 4.1. Оптимизация запросов к БД
- Использование `includes(:project)` для preloading связанных проектов
- Фильтрация на уровне БД (where date: Date.current)
- Сортировка по created_at для показа в хронологическом порядке

### 4.2. Форматирование таблицы
- Использование `Terminal::Table` для консистентного форматирования
- Группировка записей по проектам с подотчетами
- Выравнивание числовых колонок по правому краю
- Добавление разделителей между проектами

### 4.3. Обработка данных
- Группировка через `group_by(&:project)`
- Расчет промежуточных итогов по каждому проекту
- Расчет общего итога за день
- Обработка пустых описаний

## 5. Интеграционные аспекты

### 5.1. Совместимость с существующей системой
- Использование существующих моделей: `User`, `Project`, `TimeShift`, `Membership`
- Соблюдение прав доступа через фильтрацию `available_projects`
- Использование существующих методов форматирования `code()`

### 5.2. Локализация
- Все сообщения на русском языке
- Форматы даты в соответствии с локалью

### 5.3. Обработка ошибок
- Консистентная обработка ошибок с другими командами
- Предложение списка доступных проектов при ошибке

## 6. Порядок разработки

### Фаза 1: Базовая функциональность (1-2 дня)
1. Создать класс `DayCommand`
2. Реализовать основной метод `call`
3. Базовое форматирование вывода
4. Тестирование основного сценария

### Фаза 2: Фильтрация и оптимизация (1 день)
1. Добавить фильтрацию по проекту
2. Оптимизировать запросы к БД
3. Улучшить форматирование таблицы
4. Тестирование фильтрации

### Фаза 3: Обработка ошибок и UI (1 день)
1. Реализовать обработку пустых данных
2. Добавить обработку ошибок поиска проектов
3. Финализировать форматирование
4. Полное тестовое покрытие

### Фаза 4: Интеграция и рефакторинг (0.5 дня)
1. Проверка интеграции с системой
2. Код-ревью и рефакторинг
3. Финальное тестирование
4. Документация

## 7. Критерии завершения

- [ ] Команда `/day` показывает записи за текущий день
- [ ] Данные корректно группируются по проектам
- [ ] Общее количество часов рассчитывается верно
- [ ] Фильтрация по проекту работает корректно
- [ ] Обработка пустых данных и ошибок реализована
- [ ] Все тесты проходят (unit + integration)
- [ ] Код соответствует RuboCop требованиям
- [ ] Производительность в пределах NFR требований

## 8. Риски и митигация

### Риск 1: Проблемы с временными зонами
**Митигация:** Использовать `Date.current` с учетом timezone приложения

### Риск 2: Большой объем данных за день
**Митигация:** Оптимизированные запросы, лимитирование при необходимости

### Риск 3: Сложности форматирования таблицы
**Митигация:** Использование проверенного `Terminal::Table` и существующих паттернов

## 9. Последующие улучшения (Post-MVP)

- Возможность указания конкретной даты: `/day 2025-10-20`
- Экспорт в CSV/JSON формат
- Добавление графиков или визуализации
- Кэширование частых запросов
- Аналитика по производительности времени

## 10. Оценка ресурсов

- **Разработчик:** 1 senior/middle Rails разработчик
- **Время:** 3.5-4 дня (включая тестирование)
- **Зависимости:** Нет внешних зависимостей
- **Риски:** Низкие - используется существующая архитектура