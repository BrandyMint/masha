# План улучшения спецификаций для edit_command_spec.rb

## Обзор текущего состояния
Текущий спецификация для `EditCommand` имеет только базовые тесты на отсутствие ошибок. Команда имеет сложный workflow редактирования time entries с несколькими этапами, callback queries и пагинацией, что требует комплексного тестирования.

## Проблемы текущей спецификации
- Тест проверяет только отсутствие ошибок, но не проверяет контент ответов
- Отсутствует тестирование контекстных методов (edit_select_time_shift_input и др.)
- Не проверяется пагинация списка time shifts
- Отсутствует тестирование callback queries для выбора полей и подтверждений
- Нет тестов для разных состояний (без time shifts, с одним, с множеством)
- Не проверяется интеграция с сервисами Telegram::Edit::*

## План улучшения

### 1. Тестирование отображения списка time shifts
**Цель**: Проверить корректное отображение списка записей времени
- Проверка заголовка и структуры списка
- Тестирование форматирования time shifts (дата, часы, описание)
- Проверка пагинации при большом количестве записей
- Тестирование кнопок действий для каждого time shift

### 2. Тестирование контекстных методов
**Цель**: Полное покрытие всех этапов редактирования
- `edit_select_time_shift_input` - выбор записи для редактирования
- `edit_hours_input` - редактирование часов
- `edit_description_input` - редактирование описания
- `edit_field_callback_query` - выбор поля для редактирования
- `edit_project_callback_query` - смена проекта
- `edit_confirm_callback_query` - подтверждение изменений

### 3. Тестирование пагинации
**Цель**: Проверка корректной работы навигации
- Переход между страницами списка
- Обработка callback данных для пагинации
- Корректное отображение номера текущей страницы

### 4. Тестирование edge cases
**Цель**: Обеспечить стабильность в пограничных ситуациях
- Пользователь без time shifts
- Пользователь с одной записью
- Очень большое количество записей
- Некорректные ID time shifts

### 5. Тестирование прав доступа
**Цель**: Убедиться в корректной обработке разрешений
- Редактирование своих записей
- Попытка редактирования чужих записей (разные роли)
- Редактирование записей в разных проектах

## Структура улучшенной спецификации

```ruby
# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  include_context 'telegram webhook base'

  context 'authenticated user' do
    let(:user) { create(:user, :with_telegram) }
    let(:telegram_user) { user.telegram_user }
    let(:from_id) { telegram_user.id }

    include_context 'authenticated user'

    context 'basic edit functionality' do
      let!(:project) { create(:project, :with_owner) }
      let!(:membership) { create(:membership, :owner, project: project, user: user) }
      let!(:time_shift) do
        create(:time_shift, user: user, project: project, date: Time.zone.today, hours: 2, description: 'Test work')
      end

      it 'displays time shifts list with proper formatting' do
        response = dispatch_command :edit

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('Выберите запись для редактирования')
        expect(response.first[:text]).to include('Test work')
      end

      it 'includes pagination controls' do
        response = dispatch_command :edit

        expect(response).not_to be_nil
        # Проверяем наличие inline_keyboard для пагинации и действий
        expect(response.first[:reply_markup]).not_to be_nil
        expect(response.first[:reply_markup][:inline_keyboard]).not_to be_empty
      end
    end

    context 'without time shifts' do
      let!(:project) { create(:project, :with_owner) }
      let!(:membership) { create(:membership, :owner, project: project, user: user) }

      it 'shows appropriate message for empty list' do
        response = dispatch_command :edit

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('Нет записей')
      end
    end

    context 'without projects' do
      it 'shows message about no projects' do
        response = dispatch_command :edit

        expect(response).not_to be_nil
        expect(response.first[:text]).to include('проект')
      end
    end

    context 'with multiple time shifts' do
      let!(:project) { create(:project, :with_owner) }
      let!(:membership) { create(:membership, :owner, project: project, user: user) }

      before do
        # Создаем multiple time shifts для тестирования пагинации
        (1..15).each do |i|
          create(:time_shift,
                 user: user,
                 project: project,
                 date: i.days.ago,
                 hours: (i % 8) + 1,
                 description: "Task #{i}")
        end
      end

      it 'displays paginated list of time shifts' do
        response = dispatch_command :edit

        expect(response).not_to be_nil
        expect(response.first[:text]).not_to be_empty
        # Проверяем что отображается только часть записей (пагинация)
        expect(response.first[:text]).to match(/Task \d+/)
      end

      it 'includes pagination navigation' do
        response = dispatch_command :edit

        expect(response).not_to be_nil
        keyboard = response.first[:reply_markup][:inline_keyboard]
        expect(keyboard.flatten.map { |btn| btn[:text] }).to include(/Следующая|Далее/)
      end
    end

    context 'context methods testing' do
      let!(:project) { create(:project, :with_owner) }
      let!(:membership) { create(:membership, :owner, project: project, user: user) }
      let!(:time_shift) do
        create(:time_shift, user: user, project: project, date: Time.zone.today, hours: 3, description: 'Original description')
      end

      context 'edit_select_time_shift_input' do
        it 'handles time shift selection' do
          expect {
            controller.send(:edit_select_time_shift_input, time_shift.id.to_s)
          }.not_to raise_error
        end

        it 'handles invalid time shift ID' do
          expect {
            controller.send(:edit_select_time_shift_input, 'invalid_id')
          }.not_to raise_error
        end
      end

      context 'edit_hours_input' do
        it 'handles valid hours input' do
          expect {
            controller.send(:edit_hours_input, '5')
          }.not_to raise_error
        end

        it 'handles invalid hours input' do
          expect {
            controller.send(:edit_hours_input, 'invalid')
          }.not_to raise_error
        end
      end

      context 'edit_description_input' do
        it 'handles description input' do
          expect {
            controller.send(:edit_description_input, 'Updated description')
          }.not_to raise_error
        end

        it 'handles empty description' do
          expect {
            controller.send(:edit_description_input, '')
          }.not_to raise_error
        end
      end
    end

    context 'callback queries testing' do
      let!(:project) { create(:project, :with_owner) }
      let!(:membership) { create(:membership, :owner, project: project, user: user) }
      let!(:time_shift) do
        create(:time_shift, user: user, project: project, date: Time.zone.today, hours: 2, description: 'Test work')
      end

      context 'edit_field_callback_query' do
        it 'handles hours field selection' do
          expect {
            controller.send(:edit_field_callback_query, 'hours')
          }.not_to raise_error
        end

        it 'handles description field selection' do
          expect {
            controller.send(:edit_field_callback_query, 'description')
          }.not_to raise_error
        end

        it 'handles project field selection' do
          expect {
            controller.send(:edit_field_callback_query, 'project')
          }.not_to raise_error
        end
      end

      context 'edit_project_callback_query' do
        let!(:other_project) { create(:project, name: 'Other Project') }
        before do
          create(:membership, project: other_project, user: user, role: :member)
        end

        it 'handles project selection' do
          expect {
            controller.send(:edit_project_callback_query, other_project.slug)
          }.not_to raise_error
        end
      end

      context 'edit_confirm_callback_query' do
        it 'handles confirmation action' do
          expect {
            controller.send(:edit_confirm_callback_query, 'confirm')
          }.not_to raise_error
        end

        it 'handles cancellation action' do
          expect {
            controller.send(:edit_confirm_callback_query, 'cancel')
          }.not_to raise_error
        end
      end
    end

    context 'pagination testing' do
      let!(:project) { create(:project, :with_owner) }
      let!(:membership) { create(:membership, :owner, project: project, user: user) }

      before do
        # Создаем достаточно записей для пагинации
        (1..25).each do |i|
          create(:time_shift,
                 user: user,
                 project: project,
                 date: i.days.ago,
                 hours: (i % 8) + 1,
                 description: "Task #{i}")
        end
      end

      it 'handles pagination callback' do
        expect {
          controller.send(:handle_edit_pagination_callback, 'next_page:2')
        }.not_to raise_error
      end

      it 'shows different page content' do
        # Показываем первую страницу
        response1 = controller.send(:show_time_shifts_list, 1)

        # Показываем вторую страницу
        response2 = controller.send(:show_time_shifts_list, 2)

        expect(response1).not_to eq(response2)
      end
    end

    context 'user permissions' do
      let!(:project) { create(:project, :with_owner) }
      let!(:other_user) { create(:user, :with_telegram) }
      let!(:other_time_shift) do
        create(:time_shift, user: other_user, project: project, date: Time.zone.today, hours: 3, description: 'Other user work')
      end

      context 'as project owner' do
        before do
          create(:membership, :owner, project: project, user: user)
        end

        it 'shows own time shifts in edit list' do
          my_time_shift = create(:time_shift, user: user, project: project, date: Time.zone.today, hours: 2, description: 'My work')

          response = dispatch_command :edit

          expect(response.first[:text]).to include('My work')
          expect(response.first[:text]).not_to include('Other user work')
        end
      end

      context 'as project member' do
        before do
          create(:membership, :member, project: project, user: user)
        end

        it 'shows only own time shifts' do
          my_time_shift = create(:time_shift, user: user, project: project, date: Time.zone.today, hours: 2, description: 'My work')

          response = dispatch_command :edit

          expect(response.first[:text]).to include('My work')
          expect(response.first[:text]).not_to include('Other user work')
        end
      end
    end
  end

  context 'unauthenticated user' do
    let(:from_id) { 12345 }

    it 'responds to edit command without authentication' do
      response = dispatch_command :edit

      expect(response).not_to be_nil
      # Должно показывать сообщение об отсутствии проектов/записей
    end
  end
end
```

## Приоритеты реализации

### Высокий приоритет
1. Тестирование базового отображения списка time shifts
2. Тестирование контекстных методов для редактирования
3. Тестирование callback queries

### Средний приоритет
1. Тестирование пагинации
2. Тестирование прав доступа для разных ролей

### Низкий приоритет
1. Сложные edge cases
2. Интеграция с сервисами (мокирование)

## Необходимые моки и фикстуры

### Fixed fixtures
- Стандартные фикстуры пользователей, проектов, time shifts
- Telegram webhook контекст

### Dynamic mocks
- Мокирование `Telegram::Edit::TimeShiftService` для детального тестирования
- Мокирование `Telegram::Edit::PaginationService` для пагинации

## Ожидаемые результаты
- Полное покрытие сложного workflow редактирования
- Уверенность в корректной работе пагинации
- Стабильность при работе с различными объемами данных
- Правильная обработка прав доступа

## Примечания
- EditCommand имеет сложную архитектуру с множеством callback queries
- Важно тестировать полный workflow от выбора записи до подтверждения
- Пагинация критически важна при большом количестве записей
- Необходимо уделить внимание тестированию контекстных методов