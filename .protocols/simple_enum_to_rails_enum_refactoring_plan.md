# План рефакторинга: Отказ от simple_enum в пользу встроенных Rails enum

## Обзор

Проект использует гем `simple_enum` для управления ролями пользователей в модели `Membership`. Цель рефакторинга - заменить его на встроенный механизм enum Rails, что позволит:

- Уменьшить количество зависимостей
- Использовать нативные возможности Rails
- Получить автоматические валидации
- Улучшить производительность и поддержку

## Текущее состояние

### Использование simple_enum
```ruby
# app/models/membership.rb:28
as_enum :role, owner: 0, viewer: 1, member: 2
```

### Создаваемые элементы:
- Поле в БД: `role_cd` (integer)
- Методы проверки: `owner?`, `viewer?`, `member?`
- Скоупы: `owners`, `viewers`, `members`
- Константы: `Membership.roles` (возвращает `{"owner"=>0, "viewer"=>1, "member"=>2}`)

### Места использования:
1. **app/models/membership.rb** - основное определение
2. **app/helpers/application_helper.rb** - `Membership.roles.each_key`
3. **app/models/invite.rb** - валидация включения в `Membership.roles.keys`
4. **app/services/telegram_project_manager.rb** - проверка доступных ролей
5. **app/controllers/concerns/telegram_helpers.rb** - проверка доступных ролей
6. **Тесты** - прямое присвоение `role_cd: 0`

## Целевое состояние (Rails enum)

```ruby
# app/models/membership.rb
enum :role, { owner: 0, viewer: 1, member: 2 }
```

### Создаваемые элементы:
- Поле в БД: `role` (integer) - **изменение с role_cd**
- Методы проверки: `owner?`, `viewer?`, `member?` (то же самое)
- Скоупы: `owners`, `viewers`, `members` (то же самое)
- Константы: `Membership.roles` (возвращает ключи)

## План рефакторинга

### Этап 1: Подготовка

#### 1.1 Создать бэкап базы данных
```bash
# Создать бэкап перед миграцией
pg_dump mashtime_development > backup_before_enum_migration.sql
```

#### 1.2 Проанализировать все использования role_cd
- Найти все места, где используется `role_cd` напрямую
- Составить список мест для обновления

### Этап 2: Создание миграции для переименования поля

#### 2.1 Создать миграцию
```bash
bundle exec rails generate migration RenameRoleCdToRoleInMemberships
```

#### 2.2 Содержание миграции
```ruby
class RenameRoleCdToRoleInMemberships < ActiveRecord::Migration[8.0]
  def change
    rename_column :memberships, :role_cd, :role
  end
end
```

#### 2.3 Применить миграцию
```bash
bundle exec rails db:migrate
```

### Этап 3: Обновление модели Membership

#### 3.1 Заменить as_enum на enum
```ruby
# Было:
as_enum :role, owner: 0, viewer: 1, member: 2

# Станет:
enum :role, { owner: 0, viewer: 1, member: 2 }
```

#### 3.2 Обновить скоупы (если нужно)
Rails enum автоматически создает скоупы, но нужно проверить совместимость.

### Этап 4: Обновление кода

#### 4.1 Обновить app/helpers/application_helper.rb
```ruby
# Было:
Membership.roles.each_key do |role|

# Станет:
Membership.roles.keys.each do |role|
```

#### 4.2 Обновить валидации в app/models/invite.rb
```ruby
# Было:
inclusion: { in: Membership.roles.keys.map(&:to_s) }

# Станет (без изменений, но проверить):
inclusion: { in: Membership.roles.keys.map(&:to_s) }
```

#### 4.3 Обновить проверки в сервисах и контроллерах
```ruby
# Было:
Membership.roles.keys.include?(role)

# Станет (без изменений, но проверить):
Membership.roles.keys.include?(role)
```

#### 4.4 Обновить тесты
```ruby
# Было:
create(:membership, role_cd: 0)

# Станет:
create(:membership, role: :owner)
```

### Этап 5: Обновление скоупов

#### 5.1 Проверить скоупы в membership.rb
```ruby
# Было:
scope :owners, -> { where role_cd: 0 }
scope :viewers, -> { where role_cd: 1 }
scope :members, -> { where role_cd: 2 }

# Станет (Rails enum создает автоматически):
# scope :owners, -> { where role: :owner }
# scope :viewers, -> { where role: :viewer }
# scope :members, -> { where role: :member }

# Или оставить явные скоупы если нужно:
scope :owners, -> { where role: 'owner' }
scope :viewers, -> { where role: 'viewer' }
scope :members, -> { where role: 'member' }
```

#### 5.2 Обновить сложные скоупы
```ruby
# Было:
scope :viewable, -> { order 'role_cd < 2' }
scope :supervisors, -> { where 'role_cd = 0 or role_cd = 1' }

# Станет:
scope :viewable, -> { where(role: [:owner, :viewer]) }
scope :supervisors, -> { where(role: [:owner, :viewer]) }
```

### Этап 6: Удаление зависимости

#### 6.1 Обновить Gemfile
```ruby
# Удалить или закомментировать:
# gem 'simple_enum'
```

#### 6.2 Обновить зависимости
```bash
bundle install
```

### Этап 7: Тестирование

#### 7.1 Запустить тесты
```bash
make test
```

#### 7.2 Ручное тестирование функциональности
- Создание проекта
- Добавление пользователей с разными ролями
- Изменение ролей через UI
- Telegram команды управления ролями
- Проверка прав доступа

#### 7.3 Проверить производительность
- Убедиться что запросы с фильтрацией по ролям работают быстро

## Потенциальные риски и их решения

### Риск 1: Различие в API Membership.roles
**Проблема:** `Membership.roles` может возвращать другой формат
**Решение:** Проверить в консоли и адаптировать код:
```ruby
# Simple enum: {"owner"=>0, "viewer"=>1, "member"=>2}
# Rails enum: ["owner", "viewer", "member"]
# Для получения значений: Membership.roles["owner"] # 0
```

### Риск 2: Скоупы в запросах
**Проблема:** Скоупы могут работать по-другому
**Решение:** Явно определить скоупы после миграции

### Риск 3: Прямые запросы к role_cd
**Проблема:** Старый код может использовать role_cd напрямую
**Решение:** Найти и заменить все использования role_cd

### Риск 4: Тестовые фикстуры
**Проблема:** Фабрики могут использовать role_cd
**Решение:** Обновить все фабрики и тесты

## Проверочный лист

- [ ] Создан бэкап БД
- [ ] Создана и применена миграция переименования role_cd → role
- [ ] Обновлена модель Membership (as_enum → enum)
- [ ] Обновлены все скоупы в модели
- [ ] Обновлен app/helpers/application_helper.rb
- [ ] Проверены все валидации
- [ ] Обновлены все тесты
- [ ] Удален гем simple_enum из Gemfile
- [ ] Обновлены зависимости (bundle install)
- [ ] Все тесты проходят
- [ ] Ручное тестирование успешно
- [ ] Проверена производительность

## Ожидаемые преимущества

1. **Меньше зависимостей** - удаление одного гема
2. **Чистый код** - использование нативных возможностей Rails
3. **Автоматические валидации** - защита от невалидных значений
4. **Лучшая производительность** - нативная реализация
5. **Соответствие практикам** - современный подход в Rails
6. **Будущая совместимость** - поддержка со стороны Rails

## Временные затраты

- **Подготовка:** 1 час
- **Миграция БД:** 30 минут
- **Обновление кода:** 2-3 часа
- **Тестирование:** 1-2 часа
- **Итого:** 5-7 часов

## Примечания

- Миграция безопасна, так как используется только в одной модели
- Rails enum предоставляет практически идентичный API
- Рекомендуется выполнять в рамках maintenance window
- Все изменения обратимы при необходимости